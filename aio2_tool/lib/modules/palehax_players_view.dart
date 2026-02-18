import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart'; // EKLENDİ: Ekran görüntüsü için
import '../modules/palehax_players_view2.dart';

// Kendi proje yapına göre bu importların doğruluğundan emin ol
import '../data/player_data.dart' as pd;
import '../data/player_data.dart' show Player, PlayStyle;
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart'; // Kart tasarımı dosyan
// import '../modules/player_editor.dart'; // BUNU KAPATTIM, AŞAĞIYA EKLEDİM
import 'pale_webview.dart';

// ============================================================================
// BÖLÜM 1: SABİT VERİLER
// ============================================================================

final Map<String, String> teamMarketValues = {
  "Toulouse": "€96.86M",
  "Livorno": "€85.67M",
  "Werder Weremem": "€75.56M",
  "Maximilian": "€69.31M",
  "Invicta": "€63.89M",
  "Bursa Spor": "€61.82M",
  "Fenerbahçe": "€58.17M",
  "CA RIVER PLATE": "€55.70M",
  "Shamrock Rovers": "€46.48M",
  "Chelsea": "€30.81M",
  "It Spor": "€27.44M",
  "Tiyatro FC": "€24.59M",
  "Juventus": "€14.53M",
};

final Map<String, List<String>> manualTeamRosters = {
  "Bursa Spor": [
    "jesse00481⭐",
    "rodiiiwas⭐",
    "Syniox⭐",
    "xronle⭐",
    "butterfly.54",
    "dehsetzenc1",
    "efeesnmz",
    "ELSALVADOR97",
    "emirito34",
    "gok61",
    "MOVE",
    "Seishiro_Nagi",
    "symphnyn9p125dmnr",
    "Toeria",
    "wad",
    "zeeeyhyr_52"
  ],
  "CA RIVER PLATE": [
    "1wraithh⭐",
    "bigerdem⭐",
    "tykhe_theking⭐",
    ".1.ego",
    ".pulchra",
    "0ederson.",
    "ardaeryy",
    "eyvahnecdet",
    "fearless6514",
    "jaa_s",
    "jex.8",
    "Kangal",
    "lucibaba",
    "nes",
    "pies8",
    "sal.v1",
    "unfeat",
    "xclusive8888",
    "yuemt"
  ],
  "Chelsea": [
    "newstar.7kral⭐",
    "thetiran.⭐",
    "aide6589",
    "baropasha",
    "berkay.sr4",
    "brt_1",
    "eijist",
    "ekpe.udoh",
    "enessext",
    "lewissqw",
    "Marco",
    "pittson.",
    "sami00955",
    "shadeofsun",
    "shaps06",
    "shwmkr7"
  ],
  "Fenerbahçe": [
    "embiid21.⭐",
    "helauren⭐",
    "jaderduran99⭐",
    "kazein33⭐",
    "was2444⭐",
    "akamegakilll",
    "alprn41",
    "aurelioo7",
    "bachiralimye",
    "ennerxd_57557",
    "furkqn1",
    "krei10",
    "loves_gonna_get_you_kill",
    "rickyg7ornot",
    "vyxlora0x0",
    "wakamela",
    "ziya18"
  ],
  "Invicta": [
    "exploding_kittens⭐",
    "fluseps.⭐",
    "GABO⭐",
    "MAYMUN⭐",
    "8",
    "astorz.",
    "bombocan31",
    "boxlux_56235",
    "gusbecalm",
    "rivxs1ete",
    "secretexistence",
    "subasiccxdd",
    "vetzs",
    "w1rtzy"
  ],
  "It Spor": [
    "ANALHINOOOOOO⭐",
    "DELİ99⭐",
    "Josh⭐",
    "arap",
    "ardi0",
    "babayim0220",
    "Camikundaklayan31",
    "dorselitir",
    "elnenyy",
    "haciyatmaz936",
    "hizmetten",
    "hz._musa",
    "L_E_N_Q_U_E_V_O",
    "mambabaaaaaassssss",
    "mm_09.m",
    "muzteaq",
    "oburizmaspor",
    "scumbagdevourer",
    "waless42",
    "xelpahumut",
    "xxSamsunsporxx"
  ],
  "Juventus": [
    "canberkripsaw⭐",
    "noxel0⭐",
    "raulelchavo⭐",
    "boviix",
    "dall9",
    "erenka0920",
    "furkaniswood",
    "ghopzy",
    "gumerla",
    "lucisgod",
    "mertt1907",
    "obaloglu17",
    "poque2706",
    "sephomore",
    "topcu17",
    "villaea7",
    "wos_z"
  ],
  "Livorno": [
    "carpediem⭐",
    "flexible06⭐",
    "szcey⭐",
    "trexistroy⭐",
    ".anill10",
    "adilson28",
    "adolffare",
    "alp95",
    "barn_0",
    "beasy_1",
    "denkoko",
    "frkns61",
    "gracianas",
    "lui7638",
    "qweulas",
    "tokoz7",
    "vilhere",
    "vスペック"
  ],
  "Maximilian": [
    "5hinju⭐",
    "madrichaa⭐",
    "Ölümcül.⭐",
    "alanpasc",
    "arawnnn",
    "berkayy_9",
    "bouddas",
    "cevher7",
    "dogx",
    "dswrd1",
    "emman64_11558",
    "esved",
    "paidoss",
    "saikyoo_.",
    "st1wz",
    "Verone",
    "vmasterking"
  ],
  "Shamrock Rovers": [
    "Can_love_forgive_all?⭐",
    "croqs⭐",
    "Hakan_Ş.⭐",
    "glaby",
    "cubuk0",
    "devilq0u",
    "DREW_MCINTYRE",
    "duygusuz.",
    "exee.16",
    "gökhan_sazdağı",
    "leovaldez.",
    "misu123",
    "nicoloonfire",
    "nightmare5454",
    "Osmancan_Zurnacı",
    "rebic",
    "sacrios6",
    "saintmaxii",
    "signalv2",
    "sorloth33",
    "topcu24",
    "Zhou_Guanyu",
    "zlatk0vic"
  ],
  "Tiyatro FC": [
    "j4unty⭐",
    "messibaba1234⭐",
    "babaoglu_91217",
    "bossemenike",
    "izzet7979",
    "kreissa1",
    "Kylian_Mbappe",
    "lastarda97",
    "lee_07",
    "only.neco",
    "relax9782",
    "sealls.1",
    "secret7486",
    "troulax",
    "way.star",
    "westia",
    "wheloes",
    "xpyken000"
  ],
  "Toulouse": [
    "restes.1⭐",
    "scalettav.⭐",
    "gry2305",
    "juninho008",
    "klejka",
    "lanc10",
    "morutsanzei",
    "péno",
    "phyz3dd",
    "rafaeleao",
    "russellw.",
    "Saver",
    "solares9013CM",
    "soloxwa",
    "spiralstatic9582",
    "Sukemdiren",
    "sungto",
    "tzyx.",
    "vazopressin7DF",
    "Wings",
    "yldry9"
  ],
  "Werder Weremem": [
    "bnpear⭐",
    "mucolajj⭐",
    "orji⭐",
    "aguero.10",
    "ajorque",
    "au_rora7",
    "cacaa58",
    "dontdare.",
    "erling23",
    "ernlsv",
    "heathledgerz",
    "jexal",
    "klostrofobi",
    "mack",
    "mathildaxd",
    "meowmeran0",
    "monq",
    "neganhax",
    "Ronaldo_Иazário_de_Lima.",
    "schurzz8",
    "tsubasaozora_13",
    "xose_55"
  ],
};

Map<String, List<Map<String, String>>> get playStyleCategories => {
      pd.PaleHaxLoc.txt("Bitirici"): [
        {
          "name": "GameChanger",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Oyun Kurucu/Yaratıcı"
              : (pd.PaleHaxLoc.lang == "EN"
                  ? "Playmaker/Creator"
                  : "Creador de Juego"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_GameChanger")
        },
        {
          "name": "Acrobatic",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Akrobatik"
              : (pd.PaleHaxLoc.lang == "EN" ? "Acrobatic" : "Acrobático"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Acrobatic")
        },
        {
          "name": "PowerShot",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Sert Şut"
              : (pd.PaleHaxLoc.lang == "EN" ? "Power Shot" : "Tiro Potente"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_PowerShot")
        },
        {
          "name": "FinesseShot",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Plase Şut"
              : (pd.PaleHaxLoc.lang == "EN"
                  ? "Finesse Shot"
                  : "Tiro de Calidad"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_FinesseShot")
        },
        {
          "name": "ChipShot",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Aşırtma"
              : (pd.PaleHaxLoc.lang == "EN" ? "Chip Shot" : "Vaselina"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_ChipShot")
        }
      ],
      pd.PaleHaxLoc.txt("Pas"): [
        {
          "name": "IncisivePass",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Keskin Pas"
              : (pd.PaleHaxLoc.lang == "EN"
                  ? "Incisive Pass"
                  : "Pase Incisivo"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_IncisivePass")
        },
        {
          "name": "PingedPass",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Adrese Teslim"
              : (pd.PaleHaxLoc.lang == "EN" ? "Pinged Pass" : "Pase Preciso"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_PingedPass")
        },
        {
          "name": "LongBallPass",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Uzun Pas"
              : (pd.PaleHaxLoc.lang == "EN" ? "Long Ball" : "Balón Largo"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_LongBallPass")
        },
        {
          "name": "TikiTaka",
          "label": "Tiki Taka",
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_TikiTaka")
        },
        {
          "name": "WhippedPass",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Kırbaçlanmış Pas"
              : (pd.PaleHaxLoc.lang == "EN" ? "Whipped Pass" : "Pase Liftado"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_WhippedPass")
        },
        {
          "name": "Inventive",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Yaratıcı"
              : (pd.PaleHaxLoc.lang == "EN" ? "Inventive" : "Inventivo"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Inventive")
        }
      ],
      pd.PaleHaxLoc.txt("Savunma/Fiziksel"): [
        {
          "name": "Jockey",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Jokey"
              : (pd.PaleHaxLoc.lang == "EN" ? "Jockey" : "Jockey"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Jockey")
        },
        {
          "name": "Block",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Engelleyici"
              : (pd.PaleHaxLoc.lang == "EN" ? "Block" : "Bloqueo"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Block")
        },
        {
          "name": "Intercept",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Top Kesici"
              : (pd.PaleHaxLoc.lang == "EN" ? "Intercept" : "Intercepción"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Intercept")
        },
        {
          "name": "Anticipate",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Sezgici"
              : (pd.PaleHaxLoc.lang == "EN" ? "Anticipate" : "Anticipación"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Anticipate")
        },
        {
          "name": "Bruiser",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Kavgacı"
              : (pd.PaleHaxLoc.lang == "EN" ? "Bruiser" : "Leñero"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Bruiser")
        },
        {
          "name": "AerialFortress",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Hava Hakimiyeti"
              : (pd.PaleHaxLoc.lang == "EN" ? "Aerial" : "Aéreo"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_AerialFortress")
        }
      ],
      pd.PaleHaxLoc.txt("Dripling"): [
        {
          "name": "Technical",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Teknik"
              : (pd.PaleHaxLoc.lang == "EN" ? "Technical" : "Técnico"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Technical")
        },
        {
          "name": "Rapid",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Ani"
              : (pd.PaleHaxLoc.lang == "EN" ? "Rapid" : "Rápido"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Rapid")
        },
        {
          "name": "FirstTouch",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "İlk Dokunuş"
              : (pd.PaleHaxLoc.lang == "EN" ? "First Touch" : "Primer Toque"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_FirstTouch")
        },
        {
          "name": "Trickster",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Hilebaz/Sanatçı"
              : (pd.PaleHaxLoc.lang == "EN" ? "Trickster" : "Ilusionista"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Trickster")
        },
        {
          "name": "PressProven",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Baskı Yemez"
              : (pd.PaleHaxLoc.lang == "EN" ? "Press Proven" : "Resistente"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_PressProven")
        },
        {
          "name": "QuickStep",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Hızlı Adım"
              : (pd.PaleHaxLoc.lang == "EN" ? "Quick Step" : "Paso Rápido"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_QuickStep")
        }
      ],
      pd.PaleHaxLoc.txt("Kaleci"): [
        {
          "name": "FarReach",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Uzak Erişim/Atış"
              : (pd.PaleHaxLoc.lang == "EN" ? "Far Reach" : "Alcance Lejano"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_FarReach")
        },
        {
          "name": "Footwork",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Ayak Hareketleri"
              : (pd.PaleHaxLoc.lang == "EN" ? "Footwork" : "Juego de Pies"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_Footwork")
        },
        {
          "name": "CrossClaimer",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Çapraz Muhafız"
              : (pd.PaleHaxLoc.lang == "EN" ? "Cross Claimer" : "Interceptor"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_CrossClaimer")
        },
        {
          "name": "RushOut",
          "label": pd.PaleHaxLoc.lang == "TR"
              ? "Dışarı Terk"
              : (pd.PaleHaxLoc.lang == "EN" ? "Rush Out" : "Salida Rápida"),
          "desc": pd.PaleHaxLoc.getDesc("ps_desc_RushOut")
        },
      ]
    };

Map<String, String> get playStyleTranslationsReverse =>
    playStyleCategories.values
        .expand((e) => e)
        .fold({}, (map, e) => map..[e["name"]!] = e["label"]!);

final List<Map<String, dynamic>> metaPlaystyles = [
  {
    "role": "(1) GK Metas",
    "styles":
        "Ayak Hareketleri - Çapraz Muhafız - Dışarı Terk - Uzak Erişim/Atış"
  },
  {
    "role": "(3-6) CDM Metas",
    "styles":
        "Sezgici - Kavgacı - Engelleyici - Jokey - Adrese Teslim - Top Kesici"
  },
  {
    "role": "(10) CAM Metas",
    "styles":
        "Keskin Pas - Tiki Taka - Adrese Teslim - Oyun Kurucu/Yaratıcı - Yaratıcı - Sert Şut - Teknik"
  },
  {
    "role": "(7) RW Metas",
    "styles":
        "Hilebaz/Sanatçı - Oyun Kurucu/Yaratıcı - Hızlı Adım - Ani - Teknik - Sert Şut - Plase Şut - Yaratıcı"
  },
  {
    "role": "(11) LW Metas",
    "styles":
        "Hilebaz/Sanatçı - Oyun Kurucu/Yaratıcı - Hızlı Adım - Ani - Teknik - Sert Şut - Plase Şut - Yaratıcı"
  },
  {
    "role": "(9) ST Metas",
    "styles":
        "Plase Şut - Sert Şut - Baskı Yemez - Keskin Pas - İlk Dokunuş - Hava Hakimiyeti"
  },
];

Map<String, String> get cardTypeDescriptions => pd.globalCardTypes
    .asMap()
    .map((_, t) => MapEntry(t, pd.PaleHaxLoc.getDesc("card_desc_$t")));

Map<String, String> get roleDescriptions => pd.roleCategories.values
    .expand((e) => e)
    .fold({}, (map, r) => map..[r] = pd.PaleHaxLoc.getDesc("role_desc_$r"));

final Map<String, String> playStyleFileMap = {
  "GameChanger": "OyunKurucu",
  "Acrobatic": "Akrobatik",
  "PowerShot": "SertSut",
  "FinesseShot": "Plase",
  "IncisivePass": "KeskinPas",
  "PingedPass": "AdreseTeslim",
  "LongBallPass": "UzunPas",
  "TikiTaka": "TikiTaka",
  "WhippedPass": "KesmePas",
  "Inventive": "Yaratici",
  "Jockey": "Bariyer",
  "Block": "Blok",
  "Intercept": "TopKesici",
  "Anticipate": "Sezgici",
  "Bruiser": "Kavgaci",
  "AerialFortress": "HavaHakimiyeti",
  "Technical": "Teknik",
  "Rapid": "Ani",
  "FirstTouch": "IlkDokunus",
  "Trickster": "Hilebaz",
  "PressProven": "BaskiyaDayanikli",
  "QuickStep": "CabukAdim",
  "FarReach": "UzakErisim",
  "Footwork": "AyakHareketleri",
  "CrossClaimer": "CaprazMuhafiz",
  "RushOut": "DisariyaTerk",
  "SlideTackle": "KayarakMudahale"
};

final List<String> chemistryStylesList = [
  "Basic",
  "Sniper",
  "Finisher",
  "Deadeye",
  "Marksman",
  "Hawk",
  "Artist",
  "Architect",
  "Powerhouse",
  "Maestro",
  "Engine",
  "Sentinel",
  "Guardian",
  "Gladiator",
  "Backbone",
  "Anchor",
  "Hunter",
  "Catalyst",
  "Shadow",
  "GK Basic",
  "Wall",
  "Shield",
  "Cat",
  "Glove"
];

// ============================================================================
// BÖLÜM 2: ANA EKRAN VE UI (Logic)
// ============================================================================

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    return ValueListenableBuilder<String>(
      valueListenable: pd.paleHaxLangNotifier,
      builder: (context, lang, child) {
        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              bottom: TabBar(
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: pd.PaleHaxLoc.txt("OYUNCULAR")),
                  Tab(text: pd.PaleHaxLoc.txt("TAKIMLAR")),
                  Tab(text: pd.PaleHaxLoc.txt("OYUN STİLLERİ (WIKI)")),
                  Tab(text: pd.PaleHaxLoc.txt("KART TİPLERİ")),
                  Tab(text: pd.PaleHaxLoc.txt("ROLLER"))
                ],
              ),
            ),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SubTabPlayers(database: database),
                _SubTabTeams(database: database),
                const SubTabPlayStyles(),
                const SubTabCardTypes(),
                const SubTabRoles()
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubTabPlayers extends StatefulWidget {
  final AppDatabase database;
  const _SubTabPlayers({required this.database});
  @override
  State<_SubTabPlayers> createState() => _SubTabPlayersState();
}

class _SubTabPlayersState extends State<_SubTabPlayers>
    with SingleTickerProviderStateMixin {
  Player? selectedPlayer;
  int currentCardIndex = 0;
  late TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  Player _convert(dynamic t) {
    Map<String, int> st = {};
    List<PlayStyle> ps = [];
    // JSON decode hatalarını önlemek için try-catch blokları
    try {
      st = Map<String, int>.from(jsonDecode(t.statsJson));
    } catch (_) {}

    // YENİ: Style ve StyleTier okuma (Hem DB sütunu hem de JSON workaround desteği)
    String styleVal = "Temel";
    int styleTierVal = 0;

    try {
      var l = jsonDecode(t.playStylesJson) as List;
      ps = l
          .map((e) {
            String s = e.toString();
            // WORKAROUND: Stil bilgisini buradan oku
            if (s.startsWith("STYLE_INFO:")) {
              var parts = s.split(":");
              if (parts.length >= 3) {
                styleVal = parts[1];
                styleTierVal = int.tryParse(parts[2]) ?? 0;
              }
              return null; // Listeye ekleme (PlayStyle değil)
            }
            if (s.endsWith("+")) {
              return PlayStyle(s.substring(0, s.length - 1), isGold: true);
            }
            return PlayStyle(s, isGold: false);
          })
          .whereType<PlayStyle>()
          .toList(); // Null'ları temizle
    } catch (_) {}

    // WORKAROUND: DB'de kolon yoksa stats içinden oku
    int sm = st['SM'] ?? 3;
    int csIndex = st['CS'] ?? 0;
    String cs = "Basic";
    if (csIndex >= 0 && csIndex < chemistryStylesList.length) {
      cs = chemistryStylesList[csIndex];
    }

    // Eğer DB sütunu varsa oradan oku (Öncelik DB sütununda)
    try {
      if (t.style != null) styleVal = t.style;
      if (t.styleTier != null) styleTierVal = t.styleTier;
    } catch (_) {}

    return Player(
      name: t.name,
      rating: t.rating,
      position: t.position,
      playstyles: ps,
      cardType: t.cardType,
      team: t.team,
      stats: st,
      role: t.role,
      recLink: t.recLink ?? "",
      manualGoals: t.manualGoals,
      manualAssists:
          t.manualAssists, // HATA ÇÖZÜMÜ: Burayı boş liste yaptık, hata vermez.
      skillMoves: sm, // Stats'tan okunan değer
      chemistryStyle: cs, // Stats'tan okunan değer
      seasons: [], // Varsayılan boş
      matches: [], // Varsayılan boş
      style: styleVal,
      styleTier: styleTierVal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
        stream: widget.database.watchAllPlayers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          final all = snapshot.data!.map(_convert).toList();
          if (all.isEmpty)
            return Center(
                child: ElevatedButton(
                    onPressed: () => _showEditor(
                        context, null, (newP, oldP) => _save(newP, oldP)),
                    child: Text(pd.PaleHaxLoc.txt("İLK OYUNCUYU EKLE"))));

          if (selectedPlayer == null ||
              !all.any((p) => p.name == selectedPlayer!.name))
            selectedPlayer = all.first;
          else
            selectedPlayer =
                all.firstWhere((p) => p.name == selectedPlayer!.name);

          List<Player> versions =
              all.where((p) => p.name == selectedPlayer!.name).toList();
          if (currentCardIndex >= versions.length) currentCardIndex = 0;
          Player displayPlayer = versions[currentCardIndex];

          // Sidebar için sadece TEMEL kartları filtrele
          final sidebarList = all.where((p) => p.cardType == "Temel").toList();

          return Row(children: [
            Container(
                width: 260,
                decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.white10))),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Colors.purpleAccent,
                                Colors.blueAccent
                              ]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.purple.withOpacity(0.5),
                                    blurRadius: 10)
                              ]),
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15)),
                              onPressed: () =>
                                  _showGlobal(context, widget.database, (pT) {
                                    setState(() {
                                      selectedPlayer = _convert(pT);
                                      currentCardIndex = 0;
                                    });
                                  }),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.public,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(pd.PaleHaxLoc.txt("GLOBAL KARTLAR"),
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))
                                  ])))),
                  // --- VİTRİN BUTONU ---
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFF000000),
                            Color(0xFF311B92)
                          ]), // TOTS Renkleri
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.5))),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent),
                          onPressed: () =>
                              _showGlobalShowcase(context, widget.database),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars, color: Colors.cyanAccent),
                              const SizedBox(width: 8),
                              Text(pd.PaleHaxLoc.txt("VİTRİN"),
                                  style: GoogleFonts.russoOne(
                                      color: Colors.cyanAccent, fontSize: 14)),
                            ],
                          )),
                    ),
                  ),
                  // --- VİTRİN TAKIMLARI (SQUAD BUILDER) BUTONU ---
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent),
                          onPressed: () =>
                              _showSquadBuilder(context, widget.database),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_quilt, color: Colors.white),
                              SizedBox(width: 8),
                              Text(pd.PaleHaxLoc.txt("VİTRİN TAKIMLARI"),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: () => _showEditor(context, null,
                                  (newP, oldP) => _save(newP, oldP)),
                              icon: const Icon(Icons.person_add,
                                  color: Colors.black, size: 20),
                              label: Text(pd.PaleHaxLoc.txt("YENİ OYUNCU"),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent)))),
                  Expanded(
                      child: ListView.builder(
                          itemCount: sidebarList.length,
                          itemBuilder: (c, i) {
                            // Temel kartları listeliyoruz
                            final p = sidebarList[i];
                            return ListTile(
                                onTap: () => setState(() {
                                      selectedPlayer = p;
                                      currentCardIndex = 0;
                                    }),
                                selected: selectedPlayer?.name == p.name,
                                selectedTileColor:
                                    Colors.cyanAccent.withOpacity(0.1),
                                leading: Text("${p.rating}",
                                    style: GoogleFonts.russoOne(
                                        color: _getRatingColor(p.rating),
                                        fontSize: 18)),
                                title: Text(p.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis));
                          }))
                ])),
            Expanded(
                child: Column(children: [
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: Colors.black12,
                  child: Text(selectedPlayer!.name.toUpperCase(),
                      style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 5,
                          fontWeight: FontWeight.bold))),
              Container(
                  color: Colors.black26,
                  child: TabBar(
                      controller: _innerTabController,
                      indicatorColor: Colors.cyanAccent,
                      labelColor: Colors.cyanAccent,
                      unselectedLabelColor: Colors.white54,
                      tabs: [
                        Tab(text: pd.PaleHaxLoc.txt("PROFİL")),
                        Tab(text: pd.PaleHaxLoc.txt("ULTIMATE ANALİZ"))
                      ])),
              Expanded(
                  child: TabBarView(controller: _innerTabController, children: [
                _ViewProfile(
                    player: displayPlayer,
                    versions: versions,
                    onSelect: (p) => setState(() {
                          selectedPlayer = p;
                          currentCardIndex = versions.indexOf(p);
                        })),
                _ViewUltimate(
                    player: displayPlayer,
                    versions: versions,
                    index: currentCardIndex,
                    onIndex: (i) => setState(() => currentCardIndex = i),
                    context: context,
                    onSave: (newP, oldP) => _save(newP, oldP),
                    onDelete: (p) => _delete(p))
              ]))
            ]))
          ]);
        });
  }

  void _save(Player p, Player? oldP) async {
    // DÜZENLEME MANTIĞI: Eğer eski bir kayıt varsa (Edit modu), önce onu sil.
    if (oldP != null) {
      await widget.database.deletePlayerByNameAndType(oldP.name, oldP.cardType);
    }

    // WORKAROUND: Verileri stats içine göm (DB şeması değişmeden kayıt)
    p.stats['SM'] = p.skillMoves;
    p.stats['CS'] = chemistryStylesList.indexOf(p.chemistryStyle);
    if (p.stats['CS'] == -1) p.stats['CS'] = 0;

    // WORKAROUND: Stil bilgisini playStylesJson içine göm
    List<String> psList =
        p.playstyles.map((e) => e.isGold ? "${e.name}+" : e.name).toList();
    psList.add("STYLE_INFO:${p.style}:${p.styleTier}");

    dynamic companion = PlayerTablesCompanion(
        name: drift.Value(p.name),
        rating: drift.Value(p.rating),
        position: drift.Value(p.position),
        team: drift.Value(p.team),
        cardType: drift.Value(p.cardType),
        role: drift.Value(p.role),
        marketValue: drift.Value(p.marketValue),
        statsJson: drift.Value(jsonEncode(p.stats)),
        playStylesJson: drift.Value(jsonEncode(psList)),
        recLink: drift.Value(p.recLink),
        manualGoals: drift.Value(p.manualGoals),
        manualAssists: drift.Value(p.manualAssists));

    await widget.database.insertPlayer(companion);
    setState(() {});
  }

  void _delete(Player p) async {
    await widget.database.deletePlayerByNameAndType(p.name, p.cardType);
    setState(() {
      selectedPlayer = null;
    });
  }
}

class _SubTabTeams extends StatefulWidget {
  final AppDatabase database;
  const _SubTabTeams({required this.database});
  @override
  State<_SubTabTeams> createState() => _SubTabTeamsState();
}

class _SubTabTeamsState extends State<_SubTabTeams> {
  bool isWeb = false;
  Widget _btn(String t, bool a, VoidCallback o) => GestureDetector(
      onTap: o,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: BoxDecoration(
              color: a ? Colors.cyanAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: TextStyle(
                  color: a ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold))));
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 15),
      Center(
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _btn(pd.PaleHaxLoc.txt("UYGULAMA"), !isWeb,
                    () => setState(() => isWeb = false)),
                _btn(pd.PaleHaxLoc.txt("WEB SİTESİ"), isWeb,
                    () => setState(() => isWeb = true))
              ]))),
      const SizedBox(height: 15),
      Expanded(
          child: isWeb
              ? const PaleWebView(url: "https://palehaxball.com/takimlar")
              : _buildTeamsBody())
    ]);
  }

  Widget _buildTeamsBody() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
            child: Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: pd.teamLogos.keys.map((name) {
                  String? logo = pd.teamLogos[name];
                  if (name == "CA RIVER PLATE")
                    logo = "assets/takimlar/riverplate.png";
                  if (name == "It Spor") logo = "assets/takimlar/itspor.png";
                  String marketValue = teamMarketValues[name] ?? "€0M";
                  return GestureDetector(
                      onTap: () =>
                          _showTeamDialog(context, name, logo, widget.database),
                      child: Container(
                          width: 200,
                          height: 210,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                              border:
                                  Border.all(color: Colors.white12, width: 2)),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (logo != null && logo.isNotEmpty)
                                  Image.asset(logo,
                                      width: 80,
                                      height: 80,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.shield,
                                          color: Colors.white54,
                                          size: 60))
                                else
                                  const Icon(Icons.shield,
                                      color: Colors.white54, size: 60),
                                const SizedBox(height: 10),
                                Text(name,
                                    style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center),
                                Text(marketValue,
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))
                              ])));
                }).toList())));
  }
}

// ============================================================================
// BÖLÜM 3: WIKI VE YARDIMCI PENCERELER
// ============================================================================

class SubTabPlayStyles extends StatelessWidget {
  const SubTabPlayStyles({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 40),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF000000), Color(0xFF1A237E)]),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.cyanAccent.withOpacity(0.5))),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pd.PaleHaxLoc.txt("V7 META ANALİZİ"),
                          style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const Icon(Icons.info_outline, color: Colors.cyanAccent)
                    ]),
                const SizedBox(height: 25),
                ...metaPlaystyles.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(children: [
                      SizedBox(
                          width: 140,
                          child: Text(m['role'],
                              style: GoogleFonts.russoOne(
                                  color: Colors.cyanAccent, fontSize: 16))),
                      Expanded(
                          child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _buildIcons(m['styles'])))
                    ])))
              ])),
          ...getPlayStyleCategories().entries.map((entry) => Column(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text(entry.key,
                            style: GoogleFonts.orbitron(
                                color: Colors.greenAccent,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)))),
                Center(
                    child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: entry.value.map((ps) {
                          return Container(
                              width: 300,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white12)),
                              child: Row(children: [
                                Image.asset(
                                    "assets/Playstyles/${playStyleFileMap[ps['name']] ?? ps['name']}.png",
                                    width: 45,
                                    height: 45,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.help,
                                        color: Colors.white54)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(ps['label']!,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17)),
                                      Text(ps['desc']!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis)
                                    ]))
                              ]));
                        }).toList())),
                const SizedBox(height: 40)
              ]))
        ]));
  }

  List<Widget> _buildIcons(String s) {
    List<String> l = s.split(" - ");
    List<Widget> w = [];
    for (var n in l) {
      String fn = "";
      playStyleTranslationsReverse.forEach((k, v) {
        if (v == n.trim()) fn = k;
      });
      if (fn.isEmpty) fn = n.contains("Uzak") ? "FarReach" : n.trim();
      String fileName = playStyleFileMap[fn] ?? fn;
      w.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset("assets/Playstyles/$fileName.png",
            width: 22,
            height: 22,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.circle, size: 10, color: Colors.amber)),
        const SizedBox(width: 5),
        Text(n.trim(),
            style: const TextStyle(color: Colors.white, fontSize: 14))
      ]));
      if (l.indexOf(n) < l.length - 1)
        w.add(const Icon(Icons.arrow_right_alt,
            color: Colors.purpleAccent, size: 18));
    }
    return w;
  }
}

class SubTabCardTypes extends StatelessWidget {
  const SubTabCardTypes({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: const EdgeInsets.all(40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.65,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20),
        itemCount: pd.globalCardTypes.length,
        itemBuilder: (c, i) {
          String t = pd.globalCardTypes[i];
          Color clr = _getCardTypeColor(t);
          return GestureDetector(
              onTap: () => _showCardDetail(
                  context,
                  t,
                  Player(
                      name: "ÖRNEK",
                      rating: 90,
                      position: "(9) ST",
                      playstyles: [],
                      cardType: t,
                      team: "Takımsız"),
                  clr),
              child: Column(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: clr.withOpacity(0.8))),
                    child: Text(t,
                        style: GoogleFonts.orbitron(
                            color: clr,
                            fontSize: 13,
                            fontWeight: FontWeight.bold))),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                          width: 350,
                          height: 480,
                          child: FCAnimatedCard(
                              player: Player(
                                  name: "ÖRNEK",
                                  rating: 90,
                                  position: "(9) ST",
                                  playstyles: [],
                                  cardType: t,
                                  team: "Takımsız"),
                              animateOnHover: true)),
                    ),
                  ),
                )
              ]));
        });
  }

  void _showCardDetail(BuildContext c, String t, Player p, Color clr) {
    showDialog(
        context: c,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
                child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: clr, width: 2)),
                    child: Column(children: [
                      Text(t,
                          style:
                              GoogleFonts.orbitron(color: clr, fontSize: 32)),
                      const SizedBox(height: 10),
                      SizedBox(height: 480, child: FCAnimatedCard(player: p)),
                      const SizedBox(height: 15),
                      Text(cardTypeDescriptions[t] ?? t,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17)),
                      const SizedBox(height: 25),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(c),
                          child: Text(pd.PaleHaxLoc.txt("KAPAT")))
                    ])))));
  }
}

class SubTabRoles extends StatelessWidget {
  const SubTabRoles({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(40),
        children: pd.roleCategories.entries.map((e) {
          IconData ic = (e.key.contains("GK"))
              ? Icons.sports_handball
              : (e.key.contains("CDM"))
                  ? Icons.shield
                  : (e.key.contains("CAM"))
                      ? Icons.auto_awesome
                      : (e.key.contains("RW"))
                          ? Icons.flash_on
                          : Icons.sports_soccer;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(ic, color: Colors.amber, size: 32),
                  const SizedBox(width: 15),
                  Text(e.key,
                      style: GoogleFonts.orbitron(
                          color: Colors.amber, fontSize: 28))
                ]),
                const SizedBox(height: 20),
                ...e.value.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 15, left: 15),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r,
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(roleDescriptions[r] ?? r,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 15)),
                          const Divider(color: Colors.white10)
                        ]))),
                const SizedBox(height: 40)
              ]);
        }).toList());
  }
}

// --- PROFILE WIDGETS ---
class _ViewProfile extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final Function(Player) onSelect;
  const _ViewProfile(
      {required this.player, required this.versions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    List<PlayStyle> sortedPs = List.from(player.playstyles)
      ..sort((a, b) => (b.isGold ? 1 : 0).compareTo(a.isGold ? 1 : 0));
    return ListView(padding: const EdgeInsets.all(35), children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FCAnimatedCard(player: player, animateOnHover: true),
            const SizedBox(width: 50),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player.name.toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                      fontSize: 36,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text("${player.position} | ${player.team}",
                                  style: GoogleFonts.montserrat(
                                      fontSize: 20, color: Colors.white70))
                            ]),
                        Padding(
                            padding: const EdgeInsets.only(right: 150),
                            child: SizedBox(
                                width: 220,
                                height: 55,
                                child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _showDetailedStats(context, player),
                                    icon: const Icon(Icons.analytics,
                                        color: Colors.black, size: 24),
                                    label: Text(
                                        pd.PaleHaxLoc.txt("DETAYLI ANALİZ"),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))))))
                      ]),
                  const SizedBox(height: 35),
                  Text(pd.PaleHaxLoc.txt("OYUN STİLLERİ"),
                      style: GoogleFonts.orbitron(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 15),
                  Wrap(
                      spacing: 20,
                      runSpacing: 15,
                      children: sortedPs.map((ps) {
                        String translatedName =
                            playStyleTranslationsReverse[ps.name] ?? ps.name;
                        String displayName =
                            ps.isGold ? "$translatedName+" : translatedName;
                        String fileName = playStyleFileMap[ps.name] ?? ps.name;
                        String path = ps.isGold
                            ? "assets/Playstyles/${fileName}Plus.png"
                            : "assets/Playstyles/$fileName.png";
                        return SizedBox(
                            width: 110,
                            child: Column(children: [
                              Image.asset(path,
                                  width: 45,
                                  height: 45,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.help,
                                      color: Colors.white)),
                              const SizedBox(height: 8),
                              Text(displayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: ps.isGold
                                          ? Colors.amber
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: ps.isGold
                                          ? FontWeight.bold
                                          : FontWeight.normal))
                            ]));
                      }).toList()),
                  const SizedBox(height: 40),
                  if (versions.length > 1) ...[
                    Text(pd.PaleHaxLoc.txt("OYUNCUNUN DİĞER KARTLARI"),
                        style: GoogleFonts.orbitron(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 15),
                    SizedBox(
                        height: 160,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: versions.length,
                            itemBuilder: (c, i) {
                              if (versions[i] == player)
                                return const SizedBox.shrink();
                              return GestureDetector(
                                  onTap: () => onSelect(versions[i]),
                                  child: Container(
                                      margin: const EdgeInsets.only(right: 20),
                                      child: Column(children: [
                                        SizedBox(
                                            width: 100,
                                            height: 130,
                                            child: FittedBox(
                                                fit: BoxFit.contain,
                                                child: FCAnimatedCard(
                                                    player: versions[i],
                                                    animateOnHover: true))),
                                        Text(versions[i].cardType,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11))
                                      ])));
                            }))
                  ]
                ]))
          ]),
      const SizedBox(height: 40),
      _buildMatchHistory(player, true)
    ]);
  }
}

class _ViewUltimate extends StatefulWidget {
  final Player player;
  final List<Player> versions;
  final int index;
  final Function(int) onIndex;
  final BuildContext context;
  final Function(Player, Player?) onSave;
  final Function(Player) onDelete;

  const _ViewUltimate({
    super.key,
    required this.player,
    required this.versions,
    required this.index,
    required this.onIndex,
    required this.context,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_ViewUltimate> createState() => _ViewUltimateState();
}

class _ViewUltimateState extends State<_ViewUltimate> {
  late String aiDescription;
  // Manuel maç verilerini tutmak için geçici liste (DB yapısı değişmediği için UI state'inde tutuyoruz)
  List<Map<String, dynamic>> manualMatches = [];

  @override
  void initState() {
    super.initState();
    // Kayıtlı maç verilerini recLink içinden çek (JSON formatında saklıyoruz)
    if (widget.player.recLink.startsWith("[") &&
        widget.player.recLink.endsWith("]")) {
      try {
        List<dynamic> decoded = jsonDecode(widget.player.recLink);
        manualMatches =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        manualMatches = [];
      }
    } else {
      manualMatches = [];
    }
    _generateAiDescription();
  }

  @override
  void didUpdateWidget(covariant _ViewUltimate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      if (widget.player.recLink.startsWith("[") &&
          widget.player.recLink.endsWith("]")) {
        try {
          List<dynamic> decoded = jsonDecode(widget.player.recLink);
          manualMatches =
              decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) {
          manualMatches = [];
        }
      } else {
        manualMatches = [];
      }
      _generateAiDescription();
    }
  }

  void _generateAiDescription() {
    Player p = widget.player;
    List<String> sentences = [];

    // İstatistik Analizi
    int sho = p.stats['SHO'] ?? p.stats['Şut'] ?? 50;
    int pas = p.stats['PAS'] ?? p.stats['Pas'] ?? 50;
    int dri = p.stats['DRI'] ?? p.stats['Dripling'] ?? 50;
    int def = p.stats['DEF'] ?? p.stats['Defans'] ?? 50;
    int phy = p.stats['PHY'] ?? p.stats['Fizik'] ?? 50;
    int pac = p.stats['PAC'] ?? p.stats['Hız'] ?? 50;
    String styleName = p.style;

    if (sho > 85) {
      sentences.add(pd.PaleHaxLoc.ai("ai_sho_85"));
    } else if (sho > 75) {
      sentences.add(pd.PaleHaxLoc.ai("ai_sho_75"));
    }

    if (pas > 85) {
      sentences.add(pd.PaleHaxLoc.ai("ai_pas_85"));
    }

    if (dri > 85) {
      sentences.add(pd.PaleHaxLoc.ai("ai_dri_85"));
    }

    if (def > 85) {
      sentences.add(pd.PaleHaxLoc.ai("ai_def_85"));
    }

    if (phy > 85) {
      sentences.add(pd.PaleHaxLoc.ai("ai_phy_85"));
    }

    if (pac > 90) {
      sentences.add(pd.PaleHaxLoc.ai("ai_pac_90"));
    }

    // STİL ANALİZİ (YENİ)
    if (styleName != "Temel" && styleName != "Temel Kaleci") {
      String tierText = "";
      if (p.styleTier == 2)
        tierText = pd.PaleHaxLoc.ai("ai_style_tier2");
      else if (p.styleTier == 1) tierText = pd.PaleHaxLoc.ai("ai_style_tier1");

      if (p.styleTier > 0) {
        sentences.add(pd.PaleHaxLoc.ai("ai_style_perf",
            params: {"tier": tierText, "style": styleName}));
        if (p.styleTier == 2) {
          sentences.add(pd.PaleHaxLoc.ai("ai_style_master"));
        }
      }
    }

    // PlayStyle Analizi
    for (var ps in p.playstyles) {
      if (ps.name == "Acrobatic") {
        sentences.add(pd.PaleHaxLoc.getDesc("ps_desc_Acrobatic"));
      }
      if (ps.name == "PowerShot") {
        sentences.add(pd.PaleHaxLoc.getDesc("ps_desc_PowerShot"));
      }
      if (ps.name == "TikiTaka") {
        sentences.add(pd.PaleHaxLoc.getDesc("ps_desc_TikiTaka"));
      }
      if (ps.name == "Trivela") {
        sentences.add(pd.PaleHaxLoc.getDesc("ps_desc_Trivela"));
      }
      if (ps.name == "DeadBall") {
        sentences.add(pd.PaleHaxLoc.getDesc("ps_desc_DeadBall"));
      }
    }

    if (sentences.isEmpty) {
      sentences.add(pd.PaleHaxLoc.ai("ai_default"));
    }

    setState(() {
      aiDescription = sentences.join(" ");
    });
  }

  void _editDescription() {
    TextEditingController c = TextEditingController(text: aiDescription);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              title: Text(pd.PaleHaxLoc.txt("AI_ANALIZ_EDIT"),
                  style: TextStyle(color: Colors.cyanAccent)),
              content: TextField(
                controller: c,
                maxLines: 10,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    filled: true, fillColor: Colors.black26),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(pd.PaleHaxLoc.txt("AI_ANALIZ_IPTAL"))),
                ElevatedButton(
                    onPressed: () {
                      setState(() => aiDescription = c.text);
                      Navigator.pop(ctx);
                    },
                    child: Text(pd.PaleHaxLoc.txt("AI_ANALIZ_KAYDET")))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    Player player = widget.player;
    bool isGK = player.position.contains("GK");
    String? teamLogo = pd.teamLogos[player.team];
    if (player.team == "CA RIVER PLATE")
      teamLogo = "assets/takimlar/riverplate.png";
    if (player.team == "It Spor") teamLogo = "assets/takimlar/itspor.png";

    String styleDisplay = player.style;
    if (player.styleTier == 1) styleDisplay += "+";
    if (player.styleTier == 2) styleDisplay += "++";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ÜST MENÜ (EDİT / VERSİYON) ---
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.menu,
                  color: Colors.white12), // Hafif görünür
              tooltip: "Seçenekler",
              onPressed: () {
                _showCardOptions(context, player);
              },
            ),
          ),
          // --- ÜST KISIM ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KART
              FCAnimatedCard(player: player, animateOnHover: true),
              const SizedBox(width: 30),
              // BİLGİLER
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (teamLogo != null && teamLogo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Image.asset(teamLogo,
                                width: 50,
                                height: 50,
                                errorBuilder: (c, e, s) =>
                                    const SizedBox(width: 50, height: 50)),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name.toUpperCase(),
                                style: GoogleFonts.russoOne(
                                    fontSize: 36,
                                    color: Colors.white,
                                    height: 1)),
                            Text("${player.position} | ${player.team}",
                                style: GoogleFonts.montserrat(
                                    fontSize: 18, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    Text(pd.PaleHaxLoc.txt("OYUN STİLLERİ"),
                        style: GoogleFonts.russoOne(
                            fontSize: 16, color: Colors.amber)),
                    const SizedBox(height: 10),
                    _buildPlayStylesList(player),
                    const SizedBox(height: 25),

                    // YAPAY ZEKA ANALİZ KUTUSU (YENİ YERİ)
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: Colors.cyanAccent.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.05),
                                    blurRadius: 20)
                              ]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 10),
                                  Text(pd.PaleHaxLoc.txt("AI ANALİZ"),
                                      style: GoogleFonts.orbitron(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                aiDescription,
                                style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.menu,
                                color: Colors.white30, size: 20),
                            tooltip: "Analizi Düzenle",
                            onPressed: _editDescription,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 50),

                    // BİLGİ ÇUBUKLARI (INFO TAGS) - ARTIK BURADA
                    Wrap(
                      spacing: 15,
                      runSpacing: 10,
                      children: [
                        _buildInfoTag(Icons.science, pd.PaleHaxLoc.txt("Kimya"),
                            player.chemistryStyle, Colors.purpleAccent),
                        _buildInfoTag(
                            Icons.theater_comedy,
                            pd.PaleHaxLoc.txt("Rol"),
                            player.role,
                            Colors.orangeAccent),
                        // YENİ SIRALAMA: Kimya -> Rol -> Stil -> Skill
                        _buildInfoTag(Icons.style, pd.PaleHaxLoc.txt("Stil"),
                            styleDisplay, Colors.cyanAccent,
                            isNeon: true),
                        _buildInfoTag(Icons.star, pd.PaleHaxLoc.txt("Yetenek"),
                            "${player.skillMoves} ✭", Colors.yellowAccent),
                        _buildInfoTag(
                            Icons.sports_football,
                            pd.PaleHaxLoc.txt("Zayıf Ayak"),
                            "${player.stats['WF'] ?? 3} ✭",
                            Colors.redAccent),
                        _buildInfoTag(Icons.euro, pd.PaleHaxLoc.txt("Değer"),
                            player.marketValue, Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),

          // --- İSTATİSTİKLER VE PERFORMANS (YAN YANA) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOL: İSTATİSTİKLER
              Expanded(
                flex: 3,
                child: Column(
                  children: pd.statSegments.entries.map((entry) {
                    String category = entry.key;
                    List<String> statsList = entry.value;

                    if (isGK && !['Kaleci', 'Fizik', 'Zeka'].contains(category))
                      return const SizedBox.shrink();
                    if (!isGK && category == 'Kaleci')
                      return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              const Icon(Icons.bar_chart,
                                  color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 10),
                              Text(category.toUpperCase(),
                                  style: GoogleFonts.russoOne(
                                      color: Colors.cyanAccent, fontSize: 18)),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: statsList.map((statName) {
                            int value = player.stats[statName] ?? 0;
                            return _buildModernStatBox(statName, value);
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 30),
              // SAĞ: PERFORMANS GRAFİĞİ
              Expanded(flex: 2, child: _buildMatchPerformanceSection()),
            ],
          ),
        ],
      ),
    );
  }

  // Kart Seçenekleri Menüsü (Edit / Yeni Versiyon)
  void _showCardOptions(BuildContext context, Player p) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E24),
        builder: (c) {
          return Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.cyanAccent),
                title: Text(pd.PaleHaxLoc.txt("Kartı Düzenle"),
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                    pd.PaleHaxLoc.txt(
                        "Mevcut kartın özelliklerini değiştirir."),
                    style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(c);
                  _showEditor(
                      context, p, (newP, oldP) => widget.onSave(newP, oldP));
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.amber),
                title: Text(pd.PaleHaxLoc.txt("Yeni Versiyon Oluştur"),
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                    pd.PaleHaxLoc.txt(
                        "Örn: TOTS, TOTW gibi yeni bir kart çıkarır."),
                    style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(c);
                  _createVersion(
                      context, p, (newP) => widget.onSave(newP, null));
                },
              ),
            ],
          );
        });
  }

  Widget _buildMatchPerformanceSection() {
    int totalGoals = manualMatches.fold(0, (sum, m) => sum + (m['g'] as int));
    int totalAssists = manualMatches.fold(0, (sum, m) => sum + (m['a'] as int));

    // Grafik Verileri
    List<double> ratings =
        manualMatches.map((m) => (m['r'] as int).toDouble()).toList();

    // Trend Analizi
    String trend = pd.PaleHaxLoc.txt("DENGELİ");
    if (ratings.length >= 2) {
      trend = ratings.last > ratings[ratings.length - 2]
          ? pd.PaleHaxLoc.txt("YÜKSELİŞTE 📈")
          : (ratings.last < ratings[ratings.length - 2]
              ? pd.PaleHaxLoc.txt("DÜŞÜŞTE 📉")
              : pd.PaleHaxLoc.txt("DENGELİ"));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pd.PaleHaxLoc.txt("SEZON PERFORMANSI"),
                  style: GoogleFonts.orbitron(
                      color: Colors.greenAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Text(trend,
                  style: TextStyle(
                      color: trend.contains("YÜKSELİŞ")
                          ? Colors.green
                          : (trend.contains("DÜŞÜŞ")
                              ? Colors.red
                              : Colors.amber),
                      fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addMatchDialog,
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text(pd.PaleHaxLoc.txt("MAÇ EKLE"),
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard(pd.PaleHaxLoc.txt("TOPLAM GOL"), "$totalGoals",
                  Colors.orange),
              const SizedBox(width: 20),
              _statCard(pd.PaleHaxLoc.txt("TOPLAM ASİST"), "$totalAssists",
                  Colors.cyan),
              const SizedBox(width: 20),
              _statCard(pd.PaleHaxLoc.txt("MAÇ SAYISI"),
                  "${manualMatches.length}", Colors.purple),
            ],
          ),
          const SizedBox(height: 30),
          // GRAFİK ALANI (Çizgi Grafik)
          if (manualMatches.isNotEmpty)
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: CustomPaint(painter: _RatingGraphPainter(ratings)),
            )
          else
            Center(
                child: Text(pd.PaleHaxLoc.txt("Henüz maç girilmedi."),
                    style: TextStyle(color: Colors.white24))),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          // LİSTE
          ...manualMatches.map((m) => ListTile(
                leading: const Icon(Icons.sports_soccer, color: Colors.white54),
                title: Text("vs ${m['opp']}",
                    style: const TextStyle(color: Colors.white)),
                trailing: Text("G: ${m['g']}  A: ${m['a']}  R: ${m['r']}",
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
              ))
        ],
      ),
    );
  }

  Widget _statCard(String label, String val, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Column(
        children: [
          Text(val, style: GoogleFonts.russoOne(color: c, fontSize: 24)),
          Text(label,
              style: TextStyle(color: c.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  void _addMatchDialog() {
    TextEditingController oppC = TextEditingController();
    TextEditingController golC = TextEditingController(text: "0");
    TextEditingController astC = TextEditingController(text: "0");
    TextEditingController ratC = TextEditingController(text: "7");

    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              title: Text(pd.PaleHaxLoc.txt("MAÇ EKLE")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: oppC,
                      decoration: const InputDecoration(
                          labelText: "Rakip Takım", filled: true),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: golC,
                              decoration: const InputDecoration(
                                  labelText: "Gol", filled: true),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: astC,
                              decoration: const InputDecoration(
                                  labelText: "Asist", filled: true),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: ratC,
                      decoration: const InputDecoration(
                          labelText: "Maç Reytingi (1-10)", filled: true),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        manualMatches.add({
                          'opp': oppC.text,
                          'g': int.tryParse(golC.text) ?? 0,
                          'a': int.tryParse(astC.text) ?? 0,
                          'r': int.tryParse(ratC.text) ?? 6
                        });

                        // Veriyi Player nesnesine kaydet (recLink hack)
                        Player updated = widget.player;
                        // recLink alanını JSON deposu olarak kullanıyoruz
                        String jsonHistory = jsonEncode(manualMatches);
                        Player newP = Player(
                            name: updated.name,
                            rating: updated.rating,
                            position: updated.position,
                            playstyles: updated.playstyles,
                            cardType: updated.cardType,
                            team: updated.team,
                            stats: updated.stats,
                            role: updated.role,
                            skillMoves: updated.skillMoves,
                            chemistryStyle: updated.chemistryStyle,
                            marketValue: updated.marketValue,
                            recLink: jsonHistory, // BURAYA KAYDEDİYORUZ
                            manualGoals: updated.manualGoals,
                            manualAssists: updated.manualAssists);
                        widget.onSave(newP, widget.player);
                      });
                      Navigator.pop(c);
                    },
                    child: Text(pd.PaleHaxLoc.txt("Ekle")))
              ],
            ));
  }

  // DÜZELTME: PlayStyle Plus ikonlarını doğru klasörden alan fonksiyon
  Widget _buildPlayStylesList(Player p) {
    if (p.playstyles.isEmpty)
      return Text("Oyun stili yok.",
          style: GoogleFonts.montserrat(color: Colors.white54));
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: p.playstyles.map((ps) {
        // Plus ise özel klasörden, değilse normal klasörden al
        String fileName = playStyleFileMap[ps.name] ?? ps.name;
        String iconPath = ps.isGold
            ? "assets/Playstyles/${fileName}Plus.png"
            : "assets/Playstyles/$fileName.png";
        String displayName = playStyleTranslationsReverse[ps.name] ?? ps.name;

        // DÜZELTME: Profildeki gibi sabit genişlik (SizedBox)
        return SizedBox(
          width: 100, // Sabit genişlik verildi
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ps.isGold
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: ps.isGold ? Colors.amber : Colors.white24,
                      width: ps.isGold ? 2 : 1),
                  boxShadow: ps.isGold
                      ? [
                          BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 10)
                        ]
                      : [],
                ),
                child: Image.asset(
                  iconPath,
                  errorBuilder: (c, e, s) => Icon(Icons.help,
                      color: ps.isGold ? Colors.amber : Colors.white24),
                ),
              ),
              const SizedBox(height: 5),
              Text(displayName,
                  textAlign: TextAlign.center, // Ortala
                  style: TextStyle(
                      color: ps.isGold ? Colors.amber : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))
            ],
          ),
        );
      }).toList(),
    );
  }

  // YENİ: Modern Bilgi Etiketi
  Widget _buildInfoTag(IconData icon, String label, String value, Color color,
      {bool isNeon = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isNeon ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNeon ? color : color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text("$label: ",
              style:
                  GoogleFonts.montserrat(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: GoogleFonts.russoOne(
                  color: Colors.white,
                  fontSize: 14,
                  shadows:
                      isNeon ? [BoxShadow(color: color, blurRadius: 10)] : [])),
        ],
      ),
    );
  }

  // YENİ: Modern İstatistik Kutusu
  Widget _buildModernStatBox(String label, int value) {
    Color color = _getStatColor(value);
    return Container(
      width: 75, // GENİŞLETİLDİ: Uzun kelimeler (Hızlanma vb.) sığsın diye
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text("$value",
              style:
                  GoogleFonts.russoOne(fontSize: 16, color: color, height: 1)),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 8,
                color: Colors.white70,
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Renk belirleme fonksiyonu (Aynı kalabilir)
  Color _getStatColor(int value) {
    if (value >= 90) return Colors.greenAccent;
    if (value >= 80) return Colors.green;
    if (value >= 70) return Colors.amber;
    if (value >= 60) return const Color(0xFFFFA726); // Orange
    return const Color(0xFFEF5350); // Red
  }
}

// GRAFİK ÇİZİCİ
class _RatingGraphPainter extends CustomPainter {
  final List<double> data;
  _RatingGraphPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (data.isEmpty) return;

    double stepX = size.width / (data.length > 1 ? data.length - 1 : 1);
    Path path = Path();

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      // 10 reyting en üst (0), 0 reyting en alt (size.height)
      double y = size.height - ((data[i] / 10.0) * size.height);

      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ============================================================================
// BÖLÜM 4: GLOBAL YARDIMCI METODLAR VE WIDGET'LAR
// ============================================================================
