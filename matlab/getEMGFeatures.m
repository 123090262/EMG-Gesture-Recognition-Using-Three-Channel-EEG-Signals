function feat = getEMGFeatures(windowData, threshold)
    % windowData: [采样点数 x 通道数] 的单个窗口矩阵
    % threshold: 过零点检测的电压阈值
    [~, numChannels] = size(windowData);

    % 1. MAV (Mean Absolute Value) - 反映用力大小
    mav = mean(abs(windowData));

    % 2. WL (Waveform Length) - 信号复杂度
    wl = sum(abs(diff(windowData)));% 计算相邻点差值的绝对值之和

    % 3. ZC (Zero Crossings) - 频率特性
    zc = zeros(1, numChannels); %0元素行向量zc，长度为3 ---[0 0 0]
    for ch = 1:numChannels
        x = windowData(:, ch);
        crossings = (x(1:end-1) .* x(2:end) < 0) & (abs(diff(x)) > threshold); % 相邻两点异号且差值绝对值大于阈值; n-1的布尔向量-[T F T...]
        zc(ch) = sum(crossings);%[zc1 zc2 zc3]
    end

    % 4. SSC (Slope Sign Changes) -
    ssc = zeros(1, numChannels);
    for ch = 1:numChannels
        x = windowData(:, ch);
        mid = x(2:end-1); %向量
        left = x(1:end-2);
        right = x(3:end);
        peaks = ((mid > left & mid > right) | (mid < left & mid < right)) ...
                & ((abs(mid - left) > threshold) | (abs(mid - right) > threshold)); % 局部极值点，且变化幅度超过阈值（过滤噪声）
        ssc(ch) = sum(peaks);
    end

    % 输出特征向量：[MAV所有通道, WL所有通道, ZC所有通道, SSC所有通道]
    feat = [mav, wl, zc, ssc];
end