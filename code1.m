% Define simulation parameters
numSTAs = [1, 4, 8, 12, 16, 20];
throughput80211 = zeros(size(numSTAs));

rng(11, "combRecursive");
function throughput = simulateNetwork80211Toolbox(numSTA)
    CZAS_SYM = 0.1;
    
    SymulatorSieci = wirelessNetworkSimulator.init;

    APCfg = wlanDeviceConfig(Mode="AP", MCS=6, ChannelBandwidth=40000000, TransmitPower=30, RTSThreshold=0, TransmissionFormat="HE-SU", DisableRTS=true, AggregateHTMPDU=true, MPDUAggregationLimit=1);
    STCfg = wlanDeviceConfig(Mode="STA", MCS=6, ChannelBandwidth=40000000, TransmitPower=30, RTSThreshold=0, TransmissionFormat="HE-SU", DisableRTS=true, AggregateHTMPDU=true, MPDUAggregationLimit=1);

    AP = wlanNode(Name="AP", DeviceConfig=APCfg, Position=[0 0 0], MACFrameAbstraction=false, PHYAbstractionMethod="tgax-mac-calibration");

    stacje = wlanNode.empty(numSTA, 0);
    for i = 1:numSTA
        stacje(i) = wlanNode(Name="STA" + string(i), DeviceConfig=STCfg, Position=[0, 0, 0], MACFrameAbstraction=false, PHYAbstractionMethod="tgax-mac-calibration");
    end

    addNodes(SymulatorSieci, [AP, stacje]);

    for i = 1:numSTA
        associateStations(AP, stacje(i));
    end

    for i = 1:numSTA
        trafficSource = networkTrafficOnOff(DataRate=1e6, PacketSize=1024, OnTime=inf, OffTime=0);
        addTrafficSource(stacje(i), trafficSource, DestinationNode=AP);
    end

    run(SymulatorSieci, CZAS_SYM);

    %APStats = statistics(AP);
    STStats = arrayfun(@statistics, stacje);

    %APThroughput = (APStats.MAC.TransmittedPayloadBytes * 8) / CZAS_SYM;
    STAThroughput = sum(arrayfun(@(s) (s.MAC.TransmittedPayloadBytes * 8) / CZAS_SYM, STStats));

    throughput = STAThroughput / 1e6;
end

for idx = 1:length(numSTAs)
    numSTA = numSTAs(idx);
    throughput80211(idx) = simulateNetwork80211Toolbox(numSTA);
    fprintf('Number of STAs: %d, Throughput: %.2f Mb/s\n', numSTA, throughput80211(idx));
end

figure;
plot(numSTAs, throughput80211, '-o', 'DisplayName', '802.11 with RTS/CTS');
xlabel('Number of STAs');
ylabel('Throughput [Mb/s]');
legend('show');
grid on;
ylim([0, max(throughput80211) * 1.1]); % Ustawiamy limit osi Y od 0 do nieco więcej niż maksymalna wartość Throughput
title('Zależność wartości Throughput w stosunku do ilości stacji z włączonym RTS/CTS');
