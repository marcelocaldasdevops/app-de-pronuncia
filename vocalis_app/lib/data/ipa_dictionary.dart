class IpaEntry {
  final String ipa;
  final String tip;

  const IpaEntry({required this.ipa, required this.tip});
}

const Map<String, IpaEntry> ipaDictionary = {
  // Artigos e preposições
  'the': IpaEntry(ipa: '/ðə/', tip: 'Coloque a ponta da língua suavemente entre os dentes e vibre as cordas vocais.'),
  'a': IpaEntry(ipa: '/ə/', tip: 'Schwa — o som mais neutro do inglês. Muito breve e relaxado.'),
  'of': IpaEntry(ipa: '/əv/', tip: 'O som da letra "F" aqui soa como um V suave /v/.'),
  'to': IpaEntry(ipa: '/tuː/', tip: 'T aspirado com lábios levemente arredondados.'),
  'for': IpaEntry(ipa: '/fɔːr/', tip: 'Vogal aberta /ɔː/ seguida de R retroflexo.'),
  'by': IpaEntry(ipa: '/baɪ/', tip: 'Ditongo /aɪ/ — começa aberto e fecha para "i".'),
  'from': IpaEntry(ipa: '/frʌm/', tip: 'Vogal curta /ʌ/ como em "cup". Não é "from" com O.'),

  // Palavras frequentes & Sons TH
  'thought': IpaEntry(ipa: '/θɔːt/', tip: 'Sopre o ar entre os dentes sem vibrar as cordas vocais. Termine no T nítido.'),
  'rhythm': IpaEntry(ipa: '/ˈrɪð.əm/', tip: 'Sílaba tônica no início (RITH-um). O segundo som de TH é vozeado.'),
  'brought': IpaEntry(ipa: '/brɔːt/', tip: 'Vogal aberta profunda /ɔː/. A combinação "ough" soa como "ó".'),
  'calm': IpaEntry(ipa: '/kɑːm/', tip: 'O "L" é completamente mudo! Soa como "k-ahm".'),
  'his': IpaEntry(ipa: '/hɪz/', tip: 'H aspirado com saída de ar suave, finalizando com o som vibrante de Z /z/.'),
  'mind': IpaEntry(ipa: '/maɪnd/', tip: 'Ditongo /aɪ/ longo seguido de n e d bem demarcados.'),
  'could': IpaEntry(ipa: '/kʊd/', tip: 'Vogal curta /ʊ/ — o L é completamente mudo.'),
  'would': IpaEntry(ipa: '/wʊd/', tip: 'Igual a "could" mas com W. O L é mudo.'),
  'should': IpaEntry(ipa: '/ʃʊd/', tip: 'Começa com /ʃ/ (som de "sh"). O L é mudo.'),
  'water': IpaEntry(ipa: '/ˈwɔː.t̬ɚ/', tip: 'Em americano, o T soa como um D rápido (flap T).'),
  'coffee': IpaEntry(ipa: '/ˈkɑː.fi/', tip: 'Primeira sílaba tem /ɑː/ aberto. Acento no início.'),
  'please': IpaEntry(ipa: '/pliːz/', tip: 'O P é aspirado. Termine com Z vibrante, não S.'),
  'beautiful': IpaEntry(ipa: '/ˈbjuː.t̬ɪ.fəl/', tip: 'Começa com /bj/ + vogal longa /uː/. O T é flap T.'),
  'weather': IpaEntry(ipa: '/ˈwɛð.ɚ/', tip: 'TH vozeado entre vogais. Termine com schwa + R.'),
  'restaurant': IpaEntry(ipa: '/ˈres.tə.rɑːnt/', tip: 'Três sílabas em americano: RES-tuh-rahnt.'),
  'comfortable': IpaEntry(ipa: '/ˈkʌmf.tɚ.bəl/', tip: 'Apenas 3 sílabas: KUMF-ter-bul. A segunda sílaba desaparece.'),
  'schedule': IpaEntry(ipa: '/ˈsked.juːl/', tip: 'Em americano: SKED-yool. Em britânico: SHED-yool.'),
  'wednesday': IpaEntry(ipa: '/ˈwenz.deɪ/', tip: 'O D do meio é mudo: WENZ-day.'),
  'through': IpaEntry(ipa: '/θruː/', tip: 'TH não-vozeado + R + vogal longa /uː/.'),
  'although': IpaEntry(ipa: '/ɔːlˈðoʊ/', tip: 'Termina com ditongo /oʊ/ — não "ó" puro.'),
  'thoroughly': IpaEntry(ipa: '/ˈθɜːr.oʊ.li/', tip: 'TH + vogal /ɜːr/ + ditongo /oʊ/ + li.'),
  'specific': IpaEntry(ipa: '/spəˈsɪf.ɪk/', tip: 'Não adicione "i" antes do SP. Acento na segunda sílaba.'),
  'excellent': IpaEntry(ipa: '/ˈek.sə.lənt/', tip: 'Acento na primeira sílaba: EK-suh-lunt.'),
  'physician': IpaEntry(ipa: '/fɪˈzɪʃ.ən/', tip: 'Soa como fih-ZIH-shun. O PH aqui soa como F.'),
  'data': IpaEntry(ipa: '/ˈdeɪ.t̬ə/', tip: 'Em americano: DAY-tuh com flap T.'),
  'entrepreneurial': IpaEntry(ipa: '/ˌɑːn.trə.prəˈnɜːr.i.əl/', tip: 'Palavra difícil: ahn-truh-pruh-NOOR-ee-ul.'),
};
