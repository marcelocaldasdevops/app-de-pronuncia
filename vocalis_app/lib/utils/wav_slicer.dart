import 'dart:typed_data';

/// Utilitário para corte de amostras de áudio PCM 16-bit em arquivos WAV.
/// Permite recortar uma palavra ou fonema da gravação original do usuário
/// sem dependência de bibliotecas externas ou requisições adicionais de rede.
class WavSlicer {
  static const int _wavHeaderSize = 44;

  /// Recorta um buffer WAV PCM 16-bit entre [startMs] e [endMs] gerando um novo WAV válido.
  static Uint8List? slicePcm16Wav({
    required Uint8List sourceWav,
    required int startMs,
    required int endMs,
    int sampleRate = 16000,
    int channels = 1,
  }) {
    if (sourceWav.length <= _wavHeaderSize || endMs <= startMs) return null;

    final int bytesPerSample = 2; // 16-bit PCM = 2 bytes
    final int byteRate = sampleRate * channels * bytesPerSample;
    final int blockAlign = channels * bytesPerSample;

    int startByte = _wavHeaderSize + ((startMs * byteRate) ~/ 1000);
    int endByte = _wavHeaderSize + ((endMs * byteRate) ~/ 1000);

    // Alinha para múltiplo exato de blockAlign para evitar ruído de fase
    startByte -= (startByte - _wavHeaderSize) % blockAlign;
    endByte -= (endByte - _wavHeaderSize) % blockAlign;

    startByte = startByte.clamp(_wavHeaderSize, sourceWav.length);
    endByte = endByte.clamp(startByte, sourceWav.length);

    final int payloadLength = endByte - startByte;
    if (payloadLength <= 0) return null;

    final Uint8List slicedWav = Uint8List(_wavHeaderSize + payloadLength);
    // Copia cabeçalho original de 44 bytes
    slicedWav.setRange(0, _wavHeaderSize, sourceWav);
    // Copia a fatia de dados PCM
    slicedWav.setRange(_wavHeaderSize, slicedWav.length, sourceWav, startByte);

    // Atualiza ChunkSize (offset 4) e Subchunk2Size (offset 40) em Little Endian
    final ByteData headerView = ByteData.sublistView(slicedWav, 0, _wavHeaderSize);
    headerView.setUint32(4, 36 + payloadLength, Endian.little);
    headerView.setUint32(40, payloadLength, Endian.little);

    return slicedWav;
  }
}
