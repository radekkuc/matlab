% Define simulation parameters
numSTAs = [1, 4, 8, 12, 16, 20];
throughput80211 = zeros(size(numSTAs));

% Function to simulate IEEE 802.11 network using WLAN Toolbox
function throughput = simulateNetwork80211Toolbox(numSTA)
    % Set the seed for random number generator
    rng(1, "combRecursive");

    % Specify the simulation time in seconds
    simulationTime = 0.2; % Zwiększony czas symulacji

    % Initialize the wireless network simulator
    networkSimulator = wirelessNetworkSimulator.init;

    % Set the position of the AP
    apPosition = [0 0 0];

    % Set the configuration parameters for the AP and the STAs with 40 MHz bandwidth
    accessPointCfg = wlanDeviceConfig(Mode="AP", MCS=7, ChannelBandwidth=40e6, TransmitPower=20,RTSThreshold=0,DisableRTS=true ,AggregateHTMPDU=false, CWMin = 127, CWMax = 127); % AP device configuration
    stationCfg = wlanDeviceConfig(Mode="STA", MCS=5, ChannelBandwidth=40e6, TransmitPower=20, RTSThreshold=1000,DisableRTS=true ,AggregateHTMPDU=false, CWMin = 127, CWMax = 127);    % STA device configuration

    % Create an AP and STAs from the specified configuration
    accessPoint = wlanNode(Name="AP", Position=apPosition, DeviceConfig=accessPointCfg);
    stations = wlanNode.empty(numSTA, 0);
    for i = 1:numSTA
        stations(i) = wlanNode(Name="STA" + string(i), Position=apPosition, DeviceConfig=stationCfg);
    end

    % Create a WLAN network consisting of the AP and the STAs
    nodes = [accessPoint stations];

    % Associate the STAs with the AP
    associateStations(accessPoint, stations);

    % Generate an on-off application traffic pattern and add UL traffic between the STAs and the AP
    for i = 1:numSTA
        trafficSourceUL = networkTrafficOnOff(DataRate=1e6, PacketSize=2048); % Zwiększony DataRate i PacketSize
        addTrafficSource(stations(i), trafficSourceUL, DestinationNode=accessPoint, AccessCategory=0); % UL traffic from STA to AP
    end

    % Add nodes to the wireless network simulator
    addNodes(networkSimulator, nodes);

    % Run the network simulation for the specified simulation time
    run(networkSimulator, simulationTime);

    % Collect statistics and calculate throughput
    stationStats = arrayfun(@statistics, stations);
    stationThroughput = sum(arrayfun(@(s) (s.MAC.TransmittedPayloadBytes * 8) / simulationTime, stationStats));

    % Calculate average throughput
    throughput = stationThroughput / 1e6; % Throughput in Mb/s
end

% Run simulation for each number of STAs
for idx = 1:length(numSTAs)
    numSTA = numSTAs(idx);
    throughput80211(idx) = simulateNetwork80211Toolbox(numSTA);
    fprintf('Number of STAs: %d, Throughput: %.2f Mb/s\n', numSTA, throughput80211(idx));
end

% Generate plot
figure;
plot(numSTAs, throughput80211, '-o', 'DisplayName', '802.11 with RTS/CTS (Uplink Only)');
xlabel('Number of STAs');
ylabel('Throughput [Mb/s]');
legend('show');
grid on;
title('Uplink Throughput vs. Number of STAs for IEEE 802.11 with RTS/CTS');
