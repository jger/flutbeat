import 'package:grpc/grpc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../generated/telemetry.pbgrpc.dart';
import 'config_provider.dart';

part 'grpc_client_provider.g.dart';

@Riverpod(keepAlive: true)
ClientChannel grpcChannel(Ref ref) {
  final config = ref.watch(configProvider);

  final channelOptions = ChannelOptions(
    credentials: config.useTls
        ? const ChannelCredentials.secure()
        : const ChannelCredentials.insecure(),
    connectTimeout: const Duration(seconds: 5),
  );

  final channel = ClientChannel(
    config.host,
    port: config.port,
    options: channelOptions,
  );

  ref.onDispose(() {
    channel.shutdown();
  });

  return channel;
}

@Riverpod(keepAlive: true)
TelemetryServiceClient telemetryClient(Ref ref) {
  final channel = ref.watch(grpcChannelProvider);
  return TelemetryServiceClient(channel);
}

