import 'package:flutter_test/flutter_test.dart';
import 'package:vocalis_app/services/phonetic_converter.dart';

void main() {
  group('PhoneticConverter - Pronúncia Abrasileirada Dinâmica', () {
    test('Converte palavras comuns conhecidas', () {
      final friendly = PhoneticConverter.textToFriendly('I would like coffee please');
      expect(friendly.toLowerCase(), contains('ái'));
      expect(friendly.toLowerCase(), contains('uúd'));
      expect(friendly.toLowerCase(), contains('láik'));
      expect(friendly.toLowerCase(), contains('có-fi'));
      expect(friendly.toLowerCase(), contains('plíz'));
    });

    test('Preserva pontuação de interrogação no final', () {
      final friendly = PhoneticConverter.textToFriendly('How much does this cost?');
      expect(friendly.endsWith('?'), isTrue);
      expect(friendly.toLowerCase(), contains('ráu'));
      expect(friendly.toLowerCase(), contains('mâtch'));
      expect(friendly.toLowerCase(), contains('dâz'));
      expect(friendly.toLowerCase(), contains('diz'));
      expect(friendly.toLowerCase(), contains('cóst'));
    });

    test('Converte string IPA diretamente para fonética amigável', () {
      final result = PhoneticConverter.ipaToFriendly('/kʊd jʊ ˌrek.əˈmend/');
      expect(result.toLowerCase(), contains('kud'));
      expect(result.toLowerCase(), contains('iu'));
    });

    test('Lida com texto vazio graciosamente', () {
      expect(PhoneticConverter.textToFriendly(''), isEmpty);
      expect(PhoneticConverter.textToFriendly('   '), isEmpty);
      expect(PhoneticConverter.ipaToFriendly(''), isEmpty);
    });
  });
}
