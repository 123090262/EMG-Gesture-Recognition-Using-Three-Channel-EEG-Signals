clc; clear; close all;

%% 1. 参数设置
Fs = 1000;            % 采样率
WinLenMs = 200;       % 窗口长度：200ms
WinIncMs = 50;        % 窗口步长：50ms
ZC_Threshold = 0.005; % 特征提取阈值 (V)


winLen = round(WinLenMs * Fs / 1000);%1个窗口200个采样点
winInc = round(WinIncMs * Fs / 1000);

classNames = {'Rest', 'Fist', 'Grasp', 'Scissor'};
classLabels = [1, 2, 3, 4]; % 对应标签 ID

dataRootDir = 'MyEMGData';

%% 2. 遍历文件读取与特征提取
featureMatrix = []; % 特征 X
labelVector = [];   % 标签 Y

% 获取目录下所有的 .mat 文件
fileList = dir(fullfile(dataRootDir, '*.mat'));

if isempty(fileList)
    error(['no .mat file under ' dataRootDir ]);
end

fprintf('Findinf %d files，start processing...\n', length(fileList));

% 定义滤波器
[b_high, a_high] = butter(4, 20/(Fs/2), 'high');
[b_low, a_low] = butter(4, 450/(Fs/2), 'low');
d_notch = designfilt('bandstopiir','FilterOrder',2, ...
           'HalfPowerFrequency1',49,'HalfPowerFrequency2',51, ...
           'DesignMethod','butter','SampleRate',Fs);

for k = 1:length(fileList) %遍历所有文件
    fileName = fileList(k).name;       % 'data_Rest_164103.mat'
    filePath = fullfile(fileList(k).folder, fileName); %fullfile路径拼接函数

    % === A. 从文件名解析标签 ===
    foundLabel = false;
    currentLabelID = -1;

    for c = 1:length(classNames) % 遍历所有类别 ('Rest', 'Fist'...)
        targetClass = classNames{c};

        if contains(fileName, targetClass, 'IgnoreCase', true) %不区分大小写匹配
            currentLabelID = classLabels(c);
            foundLabel = true;
            fprintf('Read the file: %s -> Identified as cateory of : [%s]\n', fileName, targetClass);
            break; % 找到了就跳出循环
        end
    end

    % 如果文件名里没写这是什么动作，就跳过
    if ~foundLabel
        warning('Skip file: %s (cannot recognize cateroty of gestures)', fileName);
        continue;
    end

    % === B. 加载数据 (智能变量名读取) ===
    loadedData = load(filePath);
    vars = fieldnames(loadedData);
    rawData = loadedData.(vars{1}); % 自动提取变量，不管它叫 data_saved 还是 data

    % === C. 预处理 ===
    procData = rawData;
    procData = filtfilt(d_notch, procData);      % 去工频50Hz
    procData = filter(b_high, a_high, procData); % 去低频
    procData = filter(b_low, a_low, procData);   % 去高频

    % === D. 滑动窗口特征提取 ===
    numSamples = size(procData, 1);
    numWindows = floor((numSamples - winLen) / winInc) + 1;

    for w = 1:numWindows
        idxStart = (w-1)*winInc + 1;
        idxEnd = idxStart + winLen - 1;

        winData = procData(idxStart:idxEnd, :); %每个窗口的数据

        % 提取特征
        feats = getEMGFeatures(winData, ZC_Threshold);

        featureMatrix = [featureMatrix; feats]; %逐个窗口提取的特征进行拼接
        labelVector = [labelVector; currentLabelID];
    end
end

if isempty(labelVector)
    error('No valid data was extracted，please check whether Rest/Fist/Grasp/Scissor included in filenames');
end

%% 3. 训练机器学习模型
cv = cvpartition(labelVector, 'HoldOut', 0.2); % 划分训练集和测试集 (80% 训练, 20% 测试)
XTrain = featureMatrix(training(cv), :);
YTrain = labelVector(training(cv), :);
XTest = featureMatrix(test(cv), :);
YTest = labelVector(test(cv), :);

fprintf('training SVM model ...\n');

% 使用 fitcecoc (多分类纠错输出编码 SVM)
template = templateSVM('KernelFunction', 'linear', 'Standardize', true); %SVM模板，线性核，标准化;SVM是二分类器
model = fitcecoc(XTrain, YTrain, ...  %Fit Error-Correcting Output Codes， 多个二分类器组合成一个多分类器
    'Learners', template, ...
    'ClassNames', classLabels, ...
    'Coding', 'onevsone'); %两两构造

%% 4. 模型评估与验证
fprintf('Evaluating model...\n');
YPred = predict(model, XTest);

% 计算准确率
accuracy = sum(YPred == YTest) / length(YTest) * 100;
fprintf('========================================\n');
fprintf('Accuracy of test set: %.2f%%\n', accuracy);
fprintf('========================================\n');


%标签转换成数字
YTest_Cat = categorical(YTest, classLabels, classNames);
YPred_Cat = categorical(YPred, classLabels, classNames);

%  计算混淆矩阵数值
[confMat, order] = confusionmat(YTest_Cat, YPred_Cat);

%  使用 heatmap 替代 confusionchart
figure('Color', 'w', 'Position', [200, 200, 650, 500]);

% 绘制热力图
h = heatmap(order, order, confMat);% x轴: 预测类别, y轴: 真实类别, 数据: confMat


h.CellLabelFormat = '%d'; % CellLabelFormat 设为 '%d' 强制显示整数，0 也会显示为 0

h.Title = sprintf('EMG Gesture Recognition (Accuracy: %.1f%%)', accuracy);
h.XLabel = 'Predicted Class';
h.YLabel = 'True Class';
h.FontName = 'Arial';
h.FontSize = 12;

% 这是一个 纯白([1 1 1]) -> 深天蓝([0 0.45 0.74]) 的渐变
myBlueMap = [linspace(1, 0, 256)', linspace(1, 0.45, 256)', linspace(1, 0.74, 256)'];% 0 = 纯白, 大数值 = 深蓝

colormap(h, myBlueMap); % 将颜色应用到热力图
colorbar; % 显示右侧颜色条


%% 5. 保存模型用于实时APP
% 保存一个结构体，包含模型和预处理所需的参数
trainedModelData.model = model;
trainedModelData.winLen = winLen;
trainedModelData.classNames = classNames;
trainedModelData.threshold = ZC_Threshold;


save('MyTrainedModel.mat', 'trainedModelData');
fprintf('Model and parameters are saved as "MyTrainedModel.mat" ');
%% === 4.5 特征与标签关联强度可视化（深蓝风格） ===
fprintf('Computing feature–label association...\n');

numFeatures = size(featureMatrix, 2);
numClasses = length(classLabels);
Fmat = zeros(numFeatures, numClasses);

for fi = 1:numFeatures
    x = featureMatrix(:, fi);
    overallMean = mean(x);

    for ci = 1:numClasses
        idx = (labelVector == classLabels(ci));
        xc = x(idx);
        mc = mean(xc);
        vc = var(xc);

        % Fisher Score (类间方差 / 类内方差)
        Fmat(fi, ci) = (mc - overallMean)^2 / (vc + eps);
    end
end


% 特征名称（你可根据实际通道数自动生成）
numCh = size(procData, 2);
featNames = [
    strcat("MAV ch", string(1:numCh)), ...
    strcat("WL ch",  string(1:numCh)), ...
    strcat("ZC ch",  string(1:numCh)), ...
    strcat("SSC ch", string(1:numCh))
];

% 高区分度深蓝到亮紫/亮粉
betterBlueMap = [
    8/255   29/255   88/255   % 深蓝
    37/255  50/255  148/255
    65/255  82/255  168/255
    90/255  122/255 195/255
    121/255 167/255 216/255
    168/255 202/255 225/255
    215/255 227/255 233/255
    245/255 245/255 245/255  % 几乎白
];
betterBlueMap = interp1(linspace(0,1,size(betterBlueMap,1)), betterBlueMap, linspace(0,1,256));

% 绘制热力图
figure('Color','w','Position',[250 250 750 500]);
h2 = heatmap(classNames, featNames, Fmat);

% 不显示数字
h2.CellLabelColor = 'none';

% 样式设置
h2.Title  = 'Feature–Label Association Heatmap';
h2.XLabel = 'Gesture Class';
h2.YLabel = 'EMG Features';
h2.FontSize = 12;
h2.FontName = 'Arial';

colormap(h2, betterBlueMap);
  % 应用深蓝色风格
colorbar;                  % 显示颜色条
