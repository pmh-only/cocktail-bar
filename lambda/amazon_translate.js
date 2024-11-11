import { TranslateClient, TranslateTextCommand } from "@aws-sdk/client-translate"

// Supported Languages
// 
// Afrikaans 	af
// Albanian 	sq
// Amharic 	am
// Arabic 	ar
// Armenian 	hy
// Azerbaijani 	az
// Bengali 	bn
// Bosnian 	bs
// Bulgarian 	bg
// Catalan 	ca
// Chinese (Simplified) 	zh
// Chinese (Traditional) 	zh-TW
// Croatian 	hr
// Czech 	cs
// Danish 	da
// Dari 	fa-AF
// Dutch 	nl
// English 	en
// Estonian 	et
// Farsi (Persian) 	fa
// Filipino, Tagalog 	tl
// Finnish 	fi
// French 	fr
// French (Canada) 	fr-CA
// Georgian 	ka
// German 	de
// Greek 	el
// Gujarati 	gu
// Haitian Creole 	ht
// Hausa 	ha
// Hebrew 	he
// Hindi 	hi
// Hungarian 	hu
// Icelandic 	is
// Indonesian 	id
// Irish 	ga
// Italian 	it
// Japanese 	ja
// Kannada 	kn
// Kazakh 	kk
// Korean 	ko
// Latvian 	lv
// Lithuanian 	lt
// Macedonian 	mk
// Malay 	ms
// Malayalam 	ml
// Maltese 	mt
// Marathi 	mr
// Mongolian 	mn
// Norwegian (Bokmål) 	no
// Pashto 	ps
// Polish 	pl
// Portuguese (Brazil) 	pt
// Portuguese (Portugal) 	pt-PT
// Punjabi 	pa
// Romanian 	ro
// Russian 	ru
// Serbian 	sr
// Sinhala 	si
// Slovak 	sk
// Slovenian 	sl
// Somali 	so
// Spanish 	es
// Spanish (Mexico) 	es-MX
// Swahili 	sw
// Swedish 	sv
// Tamil 	ta
// Telugu 	te
// Thai 	th
// Turkish 	tr
// Ukrainian 	uk
// Urdu 	ur
// Uzbek 	uz
// Vietnamese 	vi
// Welsh 	cy

export const handler = async (event) => {
  const client = new TranslateClient({});
  const input = { // TranslateTextRequest
    Text: event.input, // required
    SourceLanguageCode: "en", // required
    TargetLanguageCode: "ko", // required
    // TerminologyNames: [ // ResourceNameList
    //   "STRING_VALUE",
    // ],
    // Settings: { // TranslationSettings
    //   Formality: "FORMAL" || "INFORMAL",
    //   Profanity: "MASK",
    //   Brevity: "ON"
    // }
  }

  const command = new TranslateTextCommand(input)
  const response = await client.send(command)
  // { // TranslateTextResponse
  //   TranslatedText: "STRING_VALUE", // required
  //   SourceLanguageCode: "STRING_VALUE", // required
  //   TargetLanguageCode: "STRING_VALUE", // required
  //   AppliedTerminologies: [ // AppliedTerminologyList
  //     { // AppliedTerminology
  //       Name: "STRING_VALUE",
  //       Terms: [ // TermList
  //         { // Term
  //           SourceText: "STRING_VALUE",
  //           TargetText: "STRING_VALUE",
  //         },
  //       ],
  //     },
  //   ],
  //   AppliedSettings: { // TranslationSettings
  //     Formality: "FORMAL" || "INFORMAL",
  //     Profanity: "MASK",
  //     Brevity: "ON",
  //   },
  // };
  
  
  return response.TranslatedText
}
