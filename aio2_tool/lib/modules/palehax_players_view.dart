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
// BÖLÜM 1.5: ÇEVİRİLER (TRANSLATIONS)
// ============================================================================

final Map<String, Map<String, String>> _appStrings = {
  "tr": {
    "PLAYERS": "OYUNCULAR",
    "TEAMS": "TAKIMLAR",
    "WIKI": "OYUN STİLLERİ (WIKI)",
    "CARDS": "KART TİPLERİ",
    "ROLES": "ROLLER",
    "ADD_FIRST": "İLK OYUNCUYU EKLE",
    "GLOBAL": "GLOBAL KARTLAR",
    "SHOWCASE": "VİTRİN",
    "SQUAD_BUILDER": "VİTRİN TAKIMLARI",
    "NEW_PLAYER": "YENİ OYUNCU",
    "PROFILE": "PROFİL",
    "ULTIMATE": "ULTIMATE ANALİZ",
    "APP": "UYGULAMA",
    "WEB": "WEB SİTESİ",
    "META": "V7 META ANALİZİ",
    "SQUAD_VAL": "KADRO DEĞERİ",
    "DETAILED": "DETAYLI ANALİZ",
    "OTHER_CARDS": "OYUNCUNUN DİĞER KARTLARI",
    "SEASON_PERF": "SEZON PERFORMANSI",
    "TOTAL_GOL": "TOPLAM GOL",
    "TOTAL_AST": "TOPLAM ASİST",
    "MATCHES": "MAÇ SAYISI",
    "NO_MATCH": "Henüz maç girilmedi.",
    "ADD_MATCH": "MAÇ EKLE",
    "OPPONENT": "Rakip Takım",
    "GOAL": "Gol",
    "ASSIST": "Asist",
    "RATING": "Maç Reytingi (1-10)",
    "ADD": "EKLE",
    "CLOSE": "KAPAT",
    "CANCEL": "İPTAL",
    "SAVE": "KAYDET",
    "CREATE_TITLE": "YENİ OYUNCU OLUŞTUR",
    "EDIT_TITLE": "OYUNCUYU DÜZENLE",
    "NAME": "Ad Soyad",
    "TEAM": "Takım",
    "POS": "Pozisyon",
    "CARD": "Kart Tipi",
    "ROLE": "Rol",
    "CHEM": "Kimya Stili",
    "MARKET": "Piyasa Değeri (M€)",
    "STYLE": "Oyun Stili",
    "SKILL": "Yetenek & Zayıf Ayak",
    "STATS": "İSTATİSTİKLER",
    "NORMAL_PS": "NORMAL PS",
    "PLUS_PS": "PLUS PS",
    "SEARCH": "Ara...",
    "FILTER": "Tümü",
    "SORT_RTG": "Reyting",
    "SORT_AZ": "A-Z",
    "SORT_NEW": "En Yeni",
    "OPTIONS": "Seçenekler",
    "EDIT_CARD": "Kartı Düzenle",
    "EDIT_DESC": "Mevcut kartın özelliklerini değiştirir.",
    "NEW_VER": "Yeni Versiyon Oluştur",
    "NEW_VER_DESC": "Örn: TOTS, TOTW gibi yeni bir kart çıkarır.",
    "DELETE": "Kartı Sil",
    "DEL_CONFIRM": "silinsin mi?",
    "DELETE_BTN": "Sil",
    "AI_ANALYSIS": "AI ANALİZ",
    "EDIT_AI": "Analizi Düzenle",
    "PLAYSTYLES": "OYUN STİLLERİ",
    "NO_PS": "Oyun stili yok.",
    "CHEM_L": "Kimya",
    "ROLE_L": "Rol",
    "STYLE_L": "Stil",
    "SKILL_L": "Yetenek",
    "WF_L": "Zayıf Ayak",
    "VAL_L": "Değer",
    "TREND_BAL": "DENGELİ",
    "TREND_UP": "YÜKSELİŞTE 📈",
    "TREND_DOWN": "DÜŞÜŞTE 📉",
    "GK": "KALECİLİK",
    "PHY": "FİZİKSEL",
    "MEN": "ZİHİNSEL",
    "TEAM_NAME": "TAKIM İSMİ",
    "DOWNLOAD": "İNDİR (PNG)",
    "ORIENT": "Yönü Değiştir",
    "IMG_SAVED": "Görüntü kaydedildi!",
    "CARD_NOT_FOUND": "Bu oyuncunun kartı henüz oluşturulmamış.",
    "NEW_P_TEAM": "Yeni Oyuncu",
    "MAKE_CAP": "Kaptan Yap",
    "REMOVE": "Sil",
    "TOTS_NAME": "TEAM OF THE SEASON",
    // STYLES & ROLES (TR)
    "Temel": "Temel",
    "Temel Kaleci": "Temel Kaleci",
    "Temel Defans": "Temel Defans",
    "Temel Orta Saha": "Temel Orta Saha",
    "Temel Kanat": "Temel Kanat",
    "Temel Forvet": "Temel Forvet",
    "Çizgi Kalecisi": "Çizgi Kalecisi",
    "Süpürücü Kaleci": "Süpürücü Kaleci",
    "Oyun Kurucu Kaleci": "Oyun Kurucu Kaleci",
    "Savunmatik": "Savunmatik",
    "Libero": "Libero",
    "Oyun Kurucu Stoper": "Oyun Kurucu Stoper",
    "Tutucu": "Tutucu",
    "Derin Oyun Kurucu": "Derin Oyun Kurucu",
    "Savaşçı": "Savaşçı",
    "Oyun Kurucu": "Oyun Kurucu",
    "Box to Box": "Box to Box",
    "Mezzala": "Mezzala",
    "Gölge Forvet": "Gölge Forvet",
    "Enganche": "Enganche",
    "İç Forvet": "İç Forvet",
    "Kanat Oyuncusu": "Kanat Oyuncusu",
    "Gizli Forvet": "Gizli Forvet",
    "Avcı Forvet": "Avcı Forvet",
    "Hedef Forvet": "Hedef Forvet",
    "Yanlış 9": "Yanlış 9",
    "Kanat Bek": "Kanat Bek",
    "Hücum Bek": "Hücum Bek",
  },
  "en": {
    "PLAYERS": "PLAYERS",
    "TEAMS": "TEAMS",
    "WIKI": "PLAYSTYLES (WIKI)",
    "CARDS": "CARD TYPES",
    "ROLES": "ROLES",
    "ADD_FIRST": "ADD FIRST PLAYER",
    "GLOBAL": "GLOBAL CARDS",
    "SHOWCASE": "SHOWCASE",
    "SQUAD_BUILDER": "SQUAD BUILDER",
    "NEW_PLAYER": "NEW PLAYER",
    "PROFILE": "PROFILE",
    "ULTIMATE": "ULTIMATE ANALYSIS",
    "APP": "APP",
    "WEB": "WEBSITE",
    "META": "V7 META ANALYSIS",
    "SQUAD_VAL": "SQUAD VALUE",
    "DETAILED": "DETAILED ANALYSIS",
    "OTHER_CARDS": "OTHER CARDS",
    "SEASON_PERF": "SEASON PERFORMANCE",
    "TOTAL_GOL": "TOTAL GOALS",
    "TOTAL_AST": "TOTAL ASSISTS",
    "MATCHES": "MATCHES",
    "NO_MATCH": "No matches entered yet.",
    "ADD_MATCH": "ADD MATCH",
    "OPPONENT": "Opponent",
    "GOAL": "Goals",
    "ASSIST": "Assists",
    "RATING": "Match Rating (1-10)",
    "ADD": "ADD",
    "CLOSE": "CLOSE",
    "CANCEL": "CANCEL",
    "SAVE": "SAVE",
    "CREATE_TITLE": "CREATE NEW PLAYER",
    "EDIT_TITLE": "EDIT PLAYER",
    "NAME": "Name Surname",
    "TEAM": "Team",
    "POS": "Position",
    "CARD": "Card Type",
    "ROLE": "Role",
    "CHEM": "Chemistry Style",
    "MARKET": "Market Value (M€)",
    "STYLE": "PlayStyle",
    "SKILL": "Skills & Weak Foot",
    "STATS": "STATS",
    "NORMAL_PS": "NORMAL PS",
    "PLUS_PS": "PLUS PS",
    "SEARCH": "Search...",
    "FILTER": "All",
    "SORT_RTG": "Rating",
    "SORT_AZ": "A-Z",
    "SORT_NEW": "Newest",
    "OPTIONS": "Options",
    "EDIT_CARD": "Edit Card",
    "EDIT_DESC": "Modify current card attributes.",
    "NEW_VER": "Create New Version",
    "NEW_VER_DESC": "e.g. Create TOTS, TOTW version.",
    "DELETE": "Delete Card",
    "DEL_CONFIRM": "delete?",
    "DELETE_BTN": "Delete",
    "AI_ANALYSIS": "AI ANALYSIS",
    "EDIT_AI": "Edit Analysis",
    "PLAYSTYLES": "PLAYSTYLES",
    "NO_PS": "No playstyle.",
    "CHEM_L": "Chem",
    "ROLE_L": "Role",
    "STYLE_L": "Style",
    "SKILL_L": "Skill",
    "WF_L": "Weak Foot",
    "VAL_L": "Value",
    "TREND_BAL": "BALANCED",
    "TREND_UP": "RISING 📈",
    "TREND_DOWN": "FALLING 📉",
    "GK": "GOALKEEPING",
    "PHY": "PHYSICAL",
    "MEN": "MENTAL",
    "TEAM_NAME": "TEAM NAME",
    "DOWNLOAD": "DOWNLOAD (PNG)",
    "ORIENT": "Change Orientation",
    "IMG_SAVED": "Image saved!",
    "CARD_NOT_FOUND": "Card not created yet.",
    "NEW_P_TEAM": "New Player",
    "MAKE_CAP": "Make Captain",
    "REMOVE": "Remove",
    "TOTS_NAME": "TEAM OF THE SEASON",
    // STYLES & ROLES (EN)
    "Temel": "Basic",
    "Temel Kaleci": "Basic GK",
    "Temel Defans": "Basic Def",
    "Temel Orta Saha": "Basic Mid",
    "Temel Kanat": "Basic Wing",
    "Temel Forvet": "Basic Fwd",
    "Çizgi Kalecisi": "Line Keeper",
    "Süpürücü Kaleci": "Sweeper Keeper",
    "Oyun Kurucu Kaleci": "Playmaker GK",
    "Savunmatik": "Defensive",
    "Libero": "Libero",
    "Oyun Kurucu Stoper": "Ball Playing Defender",
    "Tutucu": "Holding",
    "Derin Oyun Kurucu": "Deep Lying Playmaker",
    "Savaşçı": "Ball Winner",
    "Oyun Kurucu": "Playmaker",
    "Box to Box": "Box to Box",
    "Mezzala": "Mezzala",
    "Gölge Forvet": "Shadow Striker",
    "Enganche": "Enganche",
    "İç Forvet": "Inside Forward",
    "Kanat Oyuncusu": "Winger",
    "Gizli Forvet": "Secret Forward",
    "Avcı Forvet": "Poacher",
    "Hedef Forvet": "Target Man",
    "Yanlış 9": "False 9",
    "Kanat Bek": "Wing Back",
    "Hücum Bek": "Attacking Fullback",
  },
  "es": {
    "PLAYERS": "JUGADORES",
    "TEAMS": "EQUIPOS",
    "WIKI": "ESTILOS (WIKI)",
    "CARDS": "TIPOS DE CARTA",
    "ROLES": "ROLES",
    "ADD_FIRST": "AÑADIR PRIMER JUGADOR",
    "GLOBAL": "CARTAS GLOBALES",
    "SHOWCASE": "ESCAPARATE",
    "SQUAD_BUILDER": "CONSTRUCTOR DE EQUIPO",
    "NEW_PLAYER": "NUEVO JUGADOR",
    "PROFILE": "PERFIL",
    "ULTIMATE": "ANÁLISIS ULTIMATE",
    "APP": "APLICACIÓN",
    "WEB": "SITIO WEB",
    "META": "ANÁLISIS META V7",
    "SQUAD_VAL": "VALOR DE PLANTILLA",
    "DETAILED": "ANÁLISIS DETALLADO",
    "OTHER_CARDS": "OTRAS CARTAS",
    "SEASON_PERF": "RENDIMIENTO TEMPORADA",
    "TOTAL_GOL": "GOLES TOTALES",
    "TOTAL_AST": "ASISTENCIAS TOTALES",
    "MATCHES": "PARTIDOS",
    "NO_MATCH": "Aún no hay partidos.",
    "ADD_MATCH": "AÑADIR PARTIDO",
    "OPPONENT": "Oponente",
    "GOAL": "Goles",
    "ASSIST": "Asistencias",
    "RATING": "Valoración (1-10)",
    "ADD": "AÑADIR",
    "CLOSE": "CERRAR",
    "CANCEL": "CANCELAR",
    "SAVE": "GUARDAR",
    "CREATE_TITLE": "CREAR JUGADOR",
    "EDIT_TITLE": "EDITAR JUGADOR",
    "NAME": "Nombre Apellido",
    "TEAM": "Equipo",
    "POS": "Posición",
    "CARD": "Tipo de Carta",
    "ROLE": "Rol",
    "CHEM": "Estilo de Química",
    "MARKET": "Valor de Mercado (M€)",
    "STYLE": "Estilo de Juego",
    "SKILL": "Habilidades y Pie Débil",
    "STATS": "ESTADÍSTICAS",
    "NORMAL_PS": "PS NORMAL",
    "PLUS_PS": "PS PLUS",
    "SEARCH": "Buscar...",
    "FILTER": "Todos",
    "SORT_RTG": "Valoración",
    "SORT_AZ": "A-Z",
    "SORT_NEW": "Más Nuevos",
    "OPTIONS": "Opciones",
    "EDIT_CARD": "Editar Carta",
    "EDIT_DESC": "Modificar atributos actuales.",
    "NEW_VER": "Crear Nueva Versión",
    "NEW_VER_DESC": "ej. Crear versión TOTS, TOTW.",
    "DELETE": "Eliminar Carta",
    "DEL_CONFIRM": "¿eliminar?",
    "DELETE_BTN": "Eliminar",
    "AI_ANALYSIS": "ANÁLISIS IA",
    "EDIT_AI": "Editar Análisis",
    "PLAYSTYLES": "ESTILOS DE JUEGO",
    "NO_PS": "Sin estilo de juego.",
    "CHEM_L": "Química",
    "ROLE_L": "Rol",
    "STYLE_L": "Estilo",
    "SKILL_L": "Habilidad",
    "WF_L": "Pie Débil",
    "VAL_L": "Valor",
    "TREND_BAL": "EQUILIBRADO",
    "TREND_UP": "SUBIENDO 📈",
    "TREND_DOWN": "BAJANDO 📉",
    "GK": "PORTERO",
    "PHY": "FÍSICO",
    "MEN": "MENTAL",
    "TEAM_NAME": "NOMBRE DEL EQUIPO",
    "DOWNLOAD": "DESCARGAR (PNG)",
    "ORIENT": "Cambiar Orientación",
    "IMG_SAVED": "¡Imagen guardada!",
    "CARD_NOT_FOUND": "Carta aún no creada.",
    "NEW_P_TEAM": "Nuevo Jugador",
    "MAKE_CAP": "Hacer Capitán",
    "REMOVE": "Eliminar",
    "TOTS_NAME": "EQUIPO DE LA TEMPORADA",
    // STYLES & ROLES (ES)
    "Temel": "Básico",
    "Temel Kaleci": "Portero Básico",
    "Temel Defans": "Defensa Básico",
    "Temel Orta Saha": "Medio Básico",
    "Temel Kanat": "Extremo Básico",
    "Temel Forvet": "Delantero Básico",
    "Çizgi Kalecisi": "Portero de Línea",
    "Süpürücü Kaleci": "Portero Cierre",
    "Oyun Kurucu Kaleci": "Portero Jugón",
    "Savunmatik": "Defensivo",
    "Libero": "Líbero",
    "Oyun Kurucu Stoper": "Defensa con Toque",
    "Tutucu": "Contención",
    "Derin Oyun Kurucu": "Pivote Organizador",
    "Savaşçı": "Recuperador",
    "Oyun Kurucu": "Organizador",
    "Box to Box": "Box to Box",
    "Mezzala": "Mezzala",
    "Gölge Forvet": "Segundo Delantero",
    "Enganche": "Enganche",
    "İç Forvet": "Delantero Interior",
    "Kanat Oyuncusu": "Extremo",
    "Gizli Forvet": "Delantero Sorpresa",
    "Avcı Forvet": "Cazagoles",
    "Hedef Forvet": "Hombre Objetivo",
    "Yanlış 9": "Falso 9",
    "Kanat Bek": "Carrilero",
    "Hücum Bek": "Lateral Ofensivo",
  }
};

String t(String key, String lang) => _appStrings[lang]?[key] ?? key;

// ============================================================================
// BÖLÜM 2: ANA EKRAN VE UI (Logic)
// ============================================================================

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  String lang = "tr"; // Varsayılan Dil
  Offset _chatbotPos = const Offset(30, 500); // Chatbot başlangıç konumu

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
<<<<<<< HEAD
            elevation: 0,
            toolbarHeight: 0,
            bottom: TabBar(
=======
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              bottom: TabBar(
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white54,
                tabs: [
<<<<<<< HEAD
                  Tab(text: t("PLAYERS", lang)),
                  Tab(text: t("TEAMS", lang)),
                  Tab(text: t("WIKI", lang)),
                  Tab(text: t("CARDS", lang)),
                  Tab(text: t("ROLES", lang))
                ]),
          ),
          body: Stack(
            children: [
              TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SubTabPlayers(
                        database: database,
                        lang: lang,
                        onLangChange: (l) => setState(() => lang = l)),
                    _SubTabTeams(database: database, lang: lang),
                    SubTabPlayStyles(lang: lang),
                    const SubTabCardTypes(),
                    const SubTabRoles()
                  ]),
              // DRAGGABLE CHATBOT
              Positioned(
                left: _chatbotPos.dx,
                top: _chatbotPos.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _chatbotPos += details.delta;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2)
                        ]),
                    child: const Icon(Icons.smart_toy,
                        color: Colors.cyanAccent, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ));
=======
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
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
  }
}

class _SubTabPlayers extends StatefulWidget {
  final AppDatabase database;
  final String lang;
  final Function(String) onLangChange;
  const _SubTabPlayers(
      {required this.database, required this.lang, required this.onLangChange});
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
<<<<<<< HEAD
                    onPressed: () => _showEditor(context, null,
                        (newP, oldP) => _save(newP, oldP), widget.lang),
                    child: Text(t("ADD_FIRST", widget.lang))));
=======
                    onPressed: () => _showEditor(
                        context, null, (newP, oldP) => _save(newP, oldP)),
                    child: Text(pd.PaleHaxLoc.txt("İLK OYUNCUYU EKLE"))));
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173

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
                              onPressed: () => _showGlobal(
                                      context, widget.database, widget.lang,
                                      (pT) {
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
<<<<<<< HEAD
                                    Text(t("GLOBAL", widget.lang),
                                        style: const TextStyle(
=======
                                    Text(pd.PaleHaxLoc.txt("GLOBAL KARTLAR"),
                                        style: TextStyle(
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
                          onPressed: () => _showGlobalShowcase(
                              context, widget.database, widget.lang),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars, color: Colors.cyanAccent),
                              const SizedBox(width: 8),
<<<<<<< HEAD
                              Text(t("SHOWCASE", widget.lang),
=======
                              Text(pd.PaleHaxLoc.txt("VİTRİN"),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
                          onPressed: () => _showSquadBuilder(
                              context, widget.database, widget.lang),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
<<<<<<< HEAD
                              const Icon(Icons.view_quilt, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(t("SQUAD_BUILDER", widget.lang),
                                  style: const TextStyle(
=======
                              Icon(Icons.view_quilt, color: Colors.white),
                              SizedBox(width: 8),
                              Text(pd.PaleHaxLoc.txt("VİTRİN TAKIMLARI"),
                                  style: TextStyle(
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
                              onPressed: () => _showEditor(
                                  context,
                                  null,
                                  (newP, oldP) => _save(newP, oldP),
                                  widget.lang),
                              icon: const Icon(Icons.person_add,
                                  color: Colors.black, size: 20),
<<<<<<< HEAD
                              label: Text(t("NEW_PLAYER", widget.lang),
                                  style: const TextStyle(
=======
                              label: Text(pd.PaleHaxLoc.txt("YENİ OYUNCU"),
                                  style: TextStyle(
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
=======
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
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
              Expanded(
                  child: Stack(children: [
                Column(children: [
                  Container(
                      color: Colors.black26,
                      child: TabBar(
                          controller: _innerTabController,
                          indicatorColor: Colors.cyanAccent,
                          labelColor: Colors.cyanAccent,
                          unselectedLabelColor: Colors.white54,
                          tabs: [
                            Tab(text: t("PROFILE", widget.lang)),
                            Tab(text: t("ULTIMATE", widget.lang))
                          ])),
                  Expanded(
                      child: TabBarView(
                          controller: _innerTabController,
                          children: [
                        _ViewProfile(
                            player: displayPlayer,
                            versions: versions,
                            lang: widget.lang,
                            onSelect: (p) => setState(() {
                                  selectedPlayer = p;
                                  currentCardIndex = versions.indexOf(p);
                                })),
                        _ViewUltimate(
                            player: displayPlayer,
                            versions: versions,
                            index: currentCardIndex,
                            lang: widget.lang,
                            onIndex: (i) =>
                                setState(() => currentCardIndex = i),
                            context: context,
                            onSave: (newP, oldP) => _save(newP, oldP),
                            onDelete: (p) => _delete(p))
                      ]))
                ]),
                Positioned(
                    bottom: 10,
                    left: 10,
                    child: PopupMenuButton<String>(
                        icon: const Icon(Icons.drag_handle,
                            color: Colors.white12),
                        tooltip: "Language / Dil",
                        onSelected: widget.onLangChange,
                        itemBuilder: (c) => [
                              const PopupMenuItem(
                                  value: "tr", child: Text("Türkçe")),
                              const PopupMenuItem(
                                  value: "en", child: Text("English")),
                              const PopupMenuItem(
                                  value: "es", child: Text("Español")),
                            ]))
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
  final String lang;
  const _SubTabTeams({required this.database, required this.lang});
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
<<<<<<< HEAD
                _btn(t("APP", widget.lang), !isWeb,
                    () => setState(() => isWeb = false)),
                _btn(t("WEB", widget.lang), isWeb,
=======
                _btn(pd.PaleHaxLoc.txt("UYGULAMA"), !isWeb,
                    () => setState(() => isWeb = false)),
                _btn(pd.PaleHaxLoc.txt("WEB SİTESİ"), isWeb,
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
                      onTap: () => _showTeamDialog(
                          context, name, logo, widget.database, widget.lang),
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
  final String lang;
  const SubTabPlayStyles({super.key, required this.lang});
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
<<<<<<< HEAD
                      Text(t("META", lang),
=======
                      Text(pd.PaleHaxLoc.txt("V7 META ANALİZİ"),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
  final String lang;
  const _ViewProfile(
      {required this.player,
      required this.versions,
      required this.onSelect,
      required this.lang});

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
                                    onPressed: () => _showDetailedStats(
                                        context, player, lang),
                                    icon: const Icon(Icons.analytics,
                                        color: Colors.black, size: 24),
<<<<<<< HEAD
                                    label: Text(t("DETAYLI ANALİZ", lang),
                                        style: const TextStyle(
=======
                                    label: Text(
                                        pd.PaleHaxLoc.txt("DETAYLI ANALİZ"),
                                        style: TextStyle(
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
                  Text(t("PLAYSTYLES", lang),
=======
                  Text(pd.PaleHaxLoc.txt("OYUN STİLLERİ"),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
                    Text(t("OTHER_CARDS", lang),
=======
                    Text(pd.PaleHaxLoc.txt("OYUNCUNUN DİĞER KARTLARI"),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
  final String lang;

  const _ViewUltimate({
    super.key,
    required this.player,
    required this.versions,
    required this.index,
    required this.onIndex,
    required this.context,
    required this.onSave,
    required this.onDelete,
    required this.lang,
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
    // Dil değişirse yeniden oluştur
    if (oldWidget.lang != widget.lang) {
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
<<<<<<< HEAD
      sentences.add(t("AI_SENTENCE_1", widget.lang));
    } else if (sho > 75) {
      sentences.add(t("AI_SENTENCE_2", widget.lang));
    }

    if (pas > 85) {
      sentences.add(t("AI_SENTENCE_3", widget.lang));
    }

    if (dri > 85) {
      sentences.add(t("AI_SENTENCE_4", widget.lang));
    }

    if (def > 85) {
      sentences.add(t("AI_SENTENCE_5", widget.lang));
    }

    if (phy > 85) {
      sentences.add(t("AI_SENTENCE_6", widget.lang));
    }

    if (pac > 90) {
      sentences.add(t("AI_SENTENCE_7", widget.lang));
=======
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
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
    }

    // STİL ANALİZİ (YENİ)
    if (styleName != "Temel" && styleName != "Temel Kaleci") {
      String tierText = "";
      if (p.styleTier == 2)
<<<<<<< HEAD
        tierText = t("STYLE_TIER_2", widget.lang);
      else if (p.styleTier == 1) tierText = t("STYLE_TIER_1", widget.lang);

      if (p.styleTier > 0) {
        if (widget.lang == "tr") {
          sentences.add(
              "Oyun stili olarak tam anlamıyla $tierText $styleName performansı sergiliyor.");
        } else {
          String translatedStyle = t(styleName, widget.lang);
          sentences.add(
              "${t("AI_SENTENCE_8", widget.lang)} $tierText $translatedStyle ${t("AI_SENTENCE_9", widget.lang)}");
        }

        if (p.styleTier == 2) {
          sentences.add(t("AI_SENTENCE_10", widget.lang));
=======
        tierText = pd.PaleHaxLoc.ai("ai_style_tier2");
      else if (p.styleTier == 1) tierText = pd.PaleHaxLoc.ai("ai_style_tier1");

      if (p.styleTier > 0) {
        sentences.add(pd.PaleHaxLoc.ai("ai_style_perf",
            params: {"tier": tierText, "style": styleName}));
        if (p.styleTier == 2) {
          sentences.add(pd.PaleHaxLoc.ai("ai_style_master"));
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
        }
      }
    }

    // PlayStyle Analizi
    for (var ps in p.playstyles) {
      if (ps.name == "Acrobatic") {
<<<<<<< HEAD
        sentences.add(t("AI_SENTENCE_11", widget.lang));
      }
      if (ps.name == "PowerShot") {
        sentences.add(t("AI_SENTENCE_12", widget.lang));
      }
      if (ps.name == "TikiTaka") {
        sentences.add(t("AI_SENTENCE_13", widget.lang));
      }
      if (ps.name == "Trivela") {
        sentences.add(t("AI_SENTENCE_14", widget.lang));
      }
      if (ps.name == "DeadBall") {
        sentences.add(t("AI_SENTENCE_15", widget.lang));
=======
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
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
      }
    }

    if (sentences.isEmpty) {
<<<<<<< HEAD
      sentences.add(t("AI_SENTENCE_DEFAULT", widget.lang));
=======
      sentences.add(pd.PaleHaxLoc.ai("ai_default"));
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
              title: Text(t("EDIT_AI", widget.lang),
                  style: const TextStyle(color: Colors.cyanAccent)),
=======
              title: Text(pd.PaleHaxLoc.txt("AI_ANALIZ_EDIT"),
                  style: TextStyle(color: Colors.cyanAccent)),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
                    child: Text(t("CANCEL", widget.lang))),
=======
                    child: Text(pd.PaleHaxLoc.txt("AI_ANALIZ_IPTAL"))),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
                ElevatedButton(
                    onPressed: () {
                      setState(() => aiDescription = c.text);
                      Navigator.pop(ctx);
                    },
<<<<<<< HEAD
                    child: Text(t("SAVE", widget.lang)))
=======
                    child: Text(pd.PaleHaxLoc.txt("AI_ANALIZ_KAYDET")))
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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

    // STİL İSMİNİ ÇEVİR
    String styleDisplay = t(player.style, widget.lang);
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

<<<<<<< HEAD
                    Text(t("PLAYSTYLES", widget.lang),
=======
                    Text(pd.PaleHaxLoc.txt("OYUN STİLLERİ"),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
                                  Text(t("AI_ANALYSIS", widget.lang),
=======
                                  Text(pd.PaleHaxLoc.txt("AI ANALİZ"),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
                        _buildInfoTag(Icons.science, t("CHEM_L", widget.lang),
                            player.chemistryStyle, Colors.purpleAccent),
                        _buildInfoTag(
                            Icons.theater_comedy,
                            t("ROLE_L", widget.lang),
                            t(player.role, widget.lang), // ROLÜ ÇEVİR
                            Colors.orangeAccent),
                        // YENİ SIRALAMA: Kimya -> Rol -> Stil -> Skill
                        _buildInfoTag(Icons.style, t("STYLE_L", widget.lang),
                            styleDisplay, Colors.cyanAccent,
                            isNeon: true),
                        _buildInfoTag(Icons.star, t("SKILL_L", widget.lang),
                            "${player.skillMoves} ✭", Colors.yellowAccent),
                        _buildInfoTag(
                            Icons.sports_football,
                            t("WF_L", widget.lang),
                            "${player.stats['WF'] ?? 3} ✭",
                            Colors.redAccent),
                        _buildInfoTag(Icons.euro, t("VAL_L", widget.lang),
=======
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
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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

                    String catTrans = category == "Kaleci"
                        ? t("GK", widget.lang)
                        : (category == "Fizik"
                            ? t("PHY", widget.lang)
                            : (category == "Zeka"
                                ? t("MEN", widget.lang)
                                : category));

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
                              Text(catTrans.toUpperCase(),
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
<<<<<<< HEAD
                title: Text(t("EDIT_CARD", widget.lang),
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(t("EDIT_DESC", widget.lang),
                    style: const TextStyle(color: Colors.white54)),
=======
                title: Text(pd.PaleHaxLoc.txt("Kartı Düzenle"),
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                    pd.PaleHaxLoc.txt(
                        "Mevcut kartın özelliklerini değiştirir."),
                    style: TextStyle(color: Colors.white54)),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
                onTap: () {
                  Navigator.pop(c);
                  _showEditor(context, p,
                      (newP, oldP) => widget.onSave(newP, oldP), widget.lang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.amber),
<<<<<<< HEAD
                title: Text(t("NEW_VER", widget.lang),
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(t("NEW_VER_DESC", widget.lang),
                    style: const TextStyle(color: Colors.white54)),
=======
                title: Text(pd.PaleHaxLoc.txt("Yeni Versiyon Oluştur"),
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                    pd.PaleHaxLoc.txt(
                        "Örn: TOTS, TOTW gibi yeni bir kart çıkarır."),
                    style: TextStyle(color: Colors.white54)),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
                onTap: () {
                  Navigator.pop(c);
                  _createVersion(context, p,
                      (newP) => widget.onSave(newP, null), widget.lang);
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
<<<<<<< HEAD
    String trend = t("TREND_BAL", widget.lang);
    if (ratings.length >= 2) {
      trend = ratings.last > ratings[ratings.length - 2]
          ? t("TREND_UP", widget.lang)
          : (ratings.last < ratings[ratings.length - 2]
              ? t("TREND_DOWN", widget.lang)
              : t("TREND_BAL", widget.lang));
=======
    String trend = pd.PaleHaxLoc.txt("DENGELİ");
    if (ratings.length >= 2) {
      trend = ratings.last > ratings[ratings.length - 2]
          ? pd.PaleHaxLoc.txt("YÜKSELİŞTE 📈")
          : (ratings.last < ratings[ratings.length - 2]
              ? pd.PaleHaxLoc.txt("DÜŞÜŞTE 📉")
              : pd.PaleHaxLoc.txt("DENGELİ"));
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
              Text(t("SEASON_PERF", widget.lang),
=======
              Text(pd.PaleHaxLoc.txt("SEZON PERFORMANSI"),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
                  style: GoogleFonts.orbitron(
                      color: Colors.greenAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Text(trend,
                  style: TextStyle(
                      color: trend.contains("📈")
                          ? Colors.green
                          : (trend.contains("📉") ? Colors.red : Colors.amber),
                      fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addMatchDialog,
                icon: const Icon(Icons.add, color: Colors.black),
<<<<<<< HEAD
                label: Text(t("ADD_MATCH", widget.lang),
                    style: const TextStyle(
=======
                label: Text(pd.PaleHaxLoc.txt("MAÇ EKLE"),
                    style: TextStyle(
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
<<<<<<< HEAD
              _statCard(
                  t("TOTAL_GOL", widget.lang), "$totalGoals", Colors.orange),
              const SizedBox(width: 20),
              _statCard(
                  t("TOTAL_AST", widget.lang), "$totalAssists", Colors.cyan),
              const SizedBox(width: 20),
              _statCard(t("MATCHES", widget.lang), "${manualMatches.length}",
                  Colors.purple),
=======
              _statCard(pd.PaleHaxLoc.txt("TOPLAM GOL"), "$totalGoals",
                  Colors.orange),
              const SizedBox(width: 20),
              _statCard(pd.PaleHaxLoc.txt("TOPLAM ASİST"), "$totalAssists",
                  Colors.cyan),
              const SizedBox(width: 20),
              _statCard(pd.PaleHaxLoc.txt("MAÇ SAYISI"),
                  "${manualMatches.length}", Colors.purple),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
                child: Text(t("NO_MATCH", widget.lang),
                    style: const TextStyle(color: Colors.white24))),
=======
                child: Text(pd.PaleHaxLoc.txt("Henüz maç girilmedi."),
                    style: TextStyle(color: Colors.white24))),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
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
<<<<<<< HEAD
              title: Text(t("ADD_MATCH", widget.lang)),
=======
              title: Text(pd.PaleHaxLoc.txt("MAÇ EKLE")),
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: oppC,
                      decoration: InputDecoration(
                          labelText: t("OPPONENT", widget.lang), filled: true),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: golC,
                              decoration: InputDecoration(
                                  labelText: t("GOAL", widget.lang),
                                  filled: true),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: astC,
                              decoration: InputDecoration(
                                  labelText: t("ASSIST", widget.lang),
                                  filled: true),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: ratC,
                      decoration: InputDecoration(
                          labelText: t("RATING", widget.lang), filled: true),
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
<<<<<<< HEAD
                    child: Text(t("ADD", widget.lang)))
=======
                    child: Text(pd.PaleHaxLoc.txt("Ekle")))
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
              ],
            ));
  }

  // DÜZELTME: PlayStyle Plus ikonlarını doğru klasörden alan fonksiyon
  Widget _buildPlayStylesList(Player p) {
    if (p.playstyles.isEmpty)
      return Text(t("NO_PS", widget.lang),
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
<<<<<<< HEAD

void _showTeamDialog(BuildContext context, String teamName, String? logo,
    AppDatabase db, String lang) {
  List<String> roster = List.from(manualTeamRosters[teamName] ?? []);
  String marketValue = teamMarketValues[teamName] ?? "€0M";
  showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
            List<String> captains =
                roster.where((n) => n.contains("⭐")).toList();
            List<String> others = roster.where((n) => !n.contains("⭐")).toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            List<String> sorted = [...captains, ...others];
            return Dialog(
                backgroundColor: const Color(0xFF0D0D12),
                child: Container(
                    width: 600,
                    height: 750,
                    padding: const EdgeInsets.all(30),
                    child: Column(children: [
                      if (logo != null)
                        Image.asset(logo,
                            width: 80,
                            height: 80,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.shield, color: Colors.white)),
                      const SizedBox(height: 15),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(teamName,
                                style: GoogleFonts.orbitron(
                                    color: Colors.cyanAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                                icon: const Icon(Icons.person_add_alt_1,
                                    color: Colors.greenAccent),
                                onPressed: () => _addNewPlayerToRoster(
                                    context,
                                    teamName,
                                    lang,
                                    (newName) => setModalState(
                                        () => roster.add(newName))))
                          ]),
                      Text("${t("SQUAD_VAL", lang)}: $marketValue",
                          style: GoogleFonts.russoOne(
                              color: Colors.greenAccent, fontSize: 18)),
                      const Divider(color: Colors.white24),
                      Expanded(
                          child: ListView.builder(
                              itemCount: sorted.length,
                              itemBuilder: (c, i) {
                                String raw = sorted[i];
                                bool isCap = raw.contains("⭐");
                                String clean = raw.replaceAll("⭐", "").trim();
                                return ListTile(
                                    onTap: () =>
                                        _tryOpenCard(context, db, clean, lang),
                                    leading: Text("${i + 1}.",
                                        style: TextStyle(
                                            color: isCap
                                                ? Colors.amber
                                                : Colors.white54)),
                                    title: Text(clean,
                                        style: TextStyle(
                                            color: isCap
                                                ? Colors.amber
                                                : Colors.white,
                                            fontWeight: isCap
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isCap)
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 18),
                                          PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert,
                                                  color: Colors.white38),
                                              onSelected: (val) {
                                                if (val == 'remove')
                                                  setModalState(
                                                      () => roster.remove(raw));
                                                if (val == 'make_cap')
                                                  setModalState(() {
                                                    int idx =
                                                        roster.indexOf(raw);
                                                    roster[idx] = "$raw⭐";
                                                  });
                                              },
                                              itemBuilder: (c) => [
                                                    PopupMenuItem(
                                                        value: 'make_cap',
                                                        child: Text(t(
                                                            "MAKE_CAP", lang))),
                                                    PopupMenuItem(
                                                        value: 'remove',
                                                        child: Text(
                                                            t("REMOVE", lang),
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .redAccent)))
                                                  ])
                                        ]));
                              })),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t("CLOSE", lang)))
                    ])));
          }));
}

void _addNewPlayerToRoster(BuildContext context, String teamName, String lang,
    Function(String) onAdd) {
  TextEditingController ctrl = TextEditingController();
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              title: Text("$teamName - ${t("NEW_P_TEAM", lang)}"),
              content: TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: t("NAME", lang))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t("CANCEL", lang))),
                ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        onAdd(ctrl.text.replaceAll(" ", "_"));
                        Navigator.pop(context);
                      }
                    },
                    child: Text(t("ADD", lang)))
              ]));
}

void _tryOpenCard(BuildContext context, AppDatabase db, String playerName,
    String lang) async {
  final allPlayers = await db.select(db.playerTables).get();
  try {
    final match = allPlayers.firstWhere(
        (p) => p.name.toLowerCase().trim() == playerName.toLowerCase().trim());
    Map<String, int> st = Map<String, int>.from(jsonDecode(match.statsJson));
    List<PlayStyle> ps = (jsonDecode(match.playStylesJson) as List)
        .map((e) => PlayStyle(e.toString()))
        .toList();
    Player pObj = Player(
        name: match.name,
        rating: match.rating,
        position: match.position,
        playstyles: ps,
        cardType: match.cardType,
        team: match.team,
        stats: st,
        role: match.role);
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FCAnimatedCard(player: pObj, animateOnHover: true),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t("CLOSE", lang)))
            ])));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t("CARD_NOT_FOUND", lang)),
        backgroundColor: Colors.redAccent));
  }
}

void _showDetailedStats(BuildContext context, Player p, String lang) {
  showDialog(
      context: context,
      builder: (_) => Dialog(
          backgroundColor: const Color(0xFF101014),
          child: Container(
              width: 1200,
              height: 700,
              padding: const EdgeInsets.all(30),
              child: Column(children: [
                Text(t("DETAYLI ANALİZ", lang),
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white24, height: 30),
                Expanded(
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: pd.statSegments.entries.map((entry) {
                              return Container(
                                  width: 250,
                                  margin: const EdgeInsets.only(right: 30),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.key,
                                            style: GoogleFonts.orbitron(
                                                color: Colors.amber,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        const Divider(color: Colors.white24),
                                        const SizedBox(height: 10),
                                        ...entry.value.map((statName) {
                                          int val = p.stats[statName] ?? 50;
                                          return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(statName,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 15)),
                                                    Text("$val",
                                                        style: TextStyle(
                                                            color: val >= 80
                                                                ? Colors
                                                                    .greenAccent
                                                                : (val >= 60
                                                                    ? Colors
                                                                        .amber
                                                                    : Colors
                                                                        .redAccent),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20))
                                                  ]));
                                        })
                                      ]));
                            }).toList()))),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10),
                    child: Text(t("CLOSE", lang)))
              ]))));
}

void _showGlobal(BuildContext context, AppDatabase db, String lang,
    Function(dynamic) onSelect) {
  String sort = t("SORT_RTG", lang), filter = t("FILTER", lang), query = "";
  showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
          builder: (c, setS) => Dialog(
              backgroundColor: const Color(0xFF0D0D12),
              child: Container(
                  width: 1100,
                  height: 850,
                  padding: const EdgeInsets.all(25),
                  child: Column(children: [
                    Row(children: [
                      SizedBox(
                          width: 250,
                          child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                  hintText: t("SEARCH", lang),
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.cyanAccent)),
                              onChanged: (v) => setS(() => query = v))),
                      const SizedBox(width: 30),
                      DropdownButton<String>(
                          value: filter,
                          dropdownColor: const Color(0xFF1E1E24),
                          style: const TextStyle(color: Colors.white),
                          items: [t("FILTER", lang), ...pd.globalCardTypes]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setS(() => filter = v!)),
                      const SizedBox(width: 30),
                      DropdownButton<String>(
                          value: sort,
                          dropdownColor: const Color(0xFF1E1E24),
                          style: const TextStyle(color: Colors.white),
                          items: [
                            t("SORT_RTG", lang),
                            t("SORT_AZ", lang),
                            t("SORT_NEW", lang)
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setS(() => sort = v!)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(c))
                    ]),
                    const Divider(color: Colors.white10),
                    Expanded(
                        child: StreamBuilder<List<dynamic>>(
                            stream: db.watchFilteredPlayers(
                                searchQuery: query,
                                cardTypeFilter: filter,
                                sortOption: sort),
                            builder: (c, sn) {
                              if (!sn.hasData)
                                return const Center(
                                    child: CircularProgressIndicator());
                              return GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                          childAspectRatio: 0.65),
                                  itemCount: sn.data!.length,
                                  itemBuilder: (c, i) {
                                    final t = sn.data![i];
                                    List<PlayStyle> ps = [];
                                    try {
                                      var l =
                                          jsonDecode(t.playStylesJson) as List;
                                      ps = l
                                          .map((e) => PlayStyle(e.toString()))
                                          .toList();
                                    } catch (_) {}
                                    Player p = Player(
                                        name: t.name,
                                        rating: t.rating,
                                        position: t.position,
                                        playstyles: ps,
                                        cardType: t.cardType,
                                        team: t.team,
                                        role: t.role);
                                    return GestureDetector(
                                        onTap: () {
                                          onSelect(t);
                                          Navigator.pop(c);
                                        },
                                        child: Transform.scale(
                                            scale: 0.9,
                                            child: FCAnimatedCard(
                                                player: p,
                                                animateOnHover: true)));
                                  });
                            }))
                  ])))));
}

Widget _infoBadge(String label, String val, {Color color = Colors.white}) =>
    Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 4),
      Text(val,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16))
    ]);
Widget _statBox(String l, String v, Color c) => Container(
    padding: const EdgeInsets.all(12),
    width: 110,
    decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        border: Border.all(color: c.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(v,
          style:
              TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(l, style: TextStyle(color: c.withOpacity(0.7), fontSize: 11))
    ]));

class _MiniPitchPainter extends CustomPainter {
  final Offset playerPos;
  _MiniPitchPainter({required this.playerPos});
  @override
  void paint(Canvas c, Size s) {
    Paint lp = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), lp);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), lp);
    c.drawCircle(Offset(s.width / 2, s.height / 2), 15, lp);
    c.drawRect(
        Rect.fromLTWH(s.width * 0.25, 0, s.width * 0.5, s.height * 0.15), lp);
    c.drawRect(
        Rect.fromLTWH(
            s.width * 0.25, s.height * 0.85, s.width * 0.5, s.height * 0.15),
        lp);
    c.drawCircle(
        Offset(playerPos.dx * s.width, playerPos.dy * s.height),
        6,
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

Color _getRatingColor(int r) =>
    r >= 90 ? const Color(0xFF00FFC2) : (r >= 80 ? Colors.amber : Colors.white);
Color _getCardTypeColor(String t) {
  switch (t) {
    case "TOTS":
      return Colors.cyanAccent;
    case "BALLOND'OR":
      return Colors.amber;
    case "MVP":
      return Colors.redAccent;
    case "BAD":
      return Colors.pinkAccent;
    case "TOTW":
      return Colors.amber;
    case "TOTM":
      return const Color(0xFFE91E63);
    case "STAR":
      return Colors.cyan;
    default:
      return Colors.white;
  }
}

Widget _buildMatchHistory(Player p, bool showRec) {
  return Column(
      children: p.matches
          .map((m) =>
              Text(m.opponent, style: const TextStyle(color: Colors.white)))
          .toList());
}

Widget _buildCardMenu(BuildContext context, Player p, Function(Player) onSave,
    Function(Player) onDelete, String lang) {
  return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFF1E1E24),
      onSelected: (val) {
        if (val == 'edit')
          _showEditor(context, p, (newP, oldP) => onSave(newP),
              lang); // onSave burada sadece yeni player alıyor, wrapper gerekebilir ama _ViewProfile içinde onSave zaten tek parametreli tanımlanmış, bu yüzden _ViewProfile'ı güncellememiz gerekebilir veya _showEditor'ı uyarlamalıyız.
        // DÜZELTME: _ViewProfile içindeki onSave tek parametreli (Player). Ancak _showEditor artık (Player, Player?) istiyor.
        // Bu yüzden _ViewProfile'ı güncellemek yerine _showEditor çağrısını düzeltelim.
        _showEditor(context, p, (newP, oldP) => onSave(newP), lang);
        if (val == 'delete') {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    backgroundColor: const Color(0xFF1E1E24),
                    title: Text(t("DELETE", lang)),
                    content: Text(
                        "${p.name} (${p.cardType}) ${t("DEL_CONFIRM", lang)}"),
                    actions: [
                      TextButton(
                          child: Text(t("CANCEL", lang)),
                          onPressed: () => Navigator.pop(context)),
                      TextButton(
                          child: Text(t("DELETE_BTN", lang),
                              style: const TextStyle(color: Colors.redAccent)),
                          onPressed: () {
                            onDelete(p);
                            Navigator.pop(context);
                          })
                    ]);
              });
        }
      },
      itemBuilder: (c) => [
            PopupMenuItem(value: 'edit', child: Text(t("EDIT_CARD", lang))),
            PopupMenuItem(
                value: 'delete',
                child: Text(t("DELETE_BTN", lang),
                    style: const TextStyle(color: Colors.redAccent)))
          ]);
}

void _createVersion(
    BuildContext context, Player p, Function(Player) onSave, String lang) {
  Player nV = Player(
      name: p.name,
      rating: p.rating,
      position: p.position,
      playstyles: List.from(p.playstyles),
      team: p.team,
      role: p.role,
      skillMoves: p.skillMoves,
      chemistryStyle: p.chemistryStyle,
      cardType: "TOTW",
      stats: Map.from(p.stats),
      seasons: p.seasons,
      recLink: p.recLink,
      manualGoals: p.manualGoals,
      manualAssists: p.manualAssists);
  showDialog(
      context: context,
      builder: (c) => CreatePlayerDialog(
          playerToEdit: nV,
          isNewVersion: true,
          lang: lang,
          onSave: (p) {
            if (p != null) onSave(p);
          }));
}

// ============================================================================
// BÖLÜM 6: VİTRİN VE SQUAD BUILDER FONKSİYONLARI
// ============================================================================

void _showGlobalShowcase(
    BuildContext context, AppDatabase db, String lang) async {
  // Verileri çek
  final allRows = await db.select(db.playerTables).get();

  // Kart Tipine Göre Gruplama
  Map<String, List<Player>> groupedPlayers = {};

  // Dönüştür ve Filtrele
  for (var row in allRows) {
    // Temel kartları atla
    if (row.cardType != "Temel") {
      // Basit convert işlemi
      List<PlayStyle> ps = [];
      try {
        var l = jsonDecode(row.playStylesJson) as List;
        ps = l.map((e) {
          String s = e.toString();
          return s.endsWith("+")
              ? PlayStyle(s.substring(0, s.length - 1), isGold: true)
              : PlayStyle(s, isGold: false);
        }).toList();
      } catch (_) {}

      Player p = Player(
          name: row.name,
          rating: row.rating,
          position: row.position,
          playstyles: ps,
          cardType: row.cardType,
          team: row.team,
          stats: {},
          role: row.role ?? "Yok");

      if (!groupedPlayers.containsKey(row.cardType)) {
        groupedPlayers[row.cardType] = [];
      }
      groupedPlayers[row.cardType]!.add(p);
    }
  }

  // Her grubu kendi içinde reytinge göre sırala
  groupedPlayers.forEach((key, list) {
    list.sort((a, b) => b.rating.compareTo(a.rating));
  });

  showDialog(
      context: context,
      builder: (c) =>
          _ShowcaseDialog(groupedPlayers: groupedPlayers, lang: lang));
}

// Animasyonlu Arka Plan İçin Widget
class _ShowcaseDialog extends StatefulWidget {
  final Map<String, List<Player>> groupedPlayers;
  final String lang;
  const _ShowcaseDialog({required this.groupedPlayers, required this.lang});

  @override
  State<_ShowcaseDialog> createState() => _ShowcaseDialogState();
}

class _ShowcaseDialogState extends State<_ShowcaseDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF0D0D12), const Color(0xFF1A237E),
                      _controller.value)!,
                  Color.lerp(const Color(0xFF000000), const Color(0xFF311B92),
                      _controller.value)!,
                  Color.lerp(const Color(0xFF1A237E), const Color(0xFF4A148C),
                      _controller.value)!,
                ],
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Column(
              children: [
                // RGB / Gradient Yazı Efekti
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.purpleAccent,
                      Colors.amber
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(t("SHOWCASE", widget.lang),
                      style: GoogleFonts.russoOne(
                          color: Colors.white, // ShaderMask bunu ezecek
                          fontSize: 50,
                          letterSpacing: 10)),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.groupedPlayers.entries.map((entry) {
                        Color typeColor = _getCardTypeColor(entry.key);
                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // ORTALA
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center, // ORTALA
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [typeColor, Colors.white],
                                    ).createShader(bounds),
                                    child: Text(entry.key,
                                        style: GoogleFonts.orbitron(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 30,
                              runSpacing: 30,
                              alignment:
                                  WrapAlignment.center, // KARTLARI ORTALA
                              children: entry.value
                                  .map((p) => Transform.scale(
                                      scale: 1.1,
                                      child: FCAnimatedCard(
                                          player: p, animateOnHover: true)))
                                  .toList(),
                            ),
                            const SizedBox(height: 60), // BOŞLUK ARTTIRILDI
                            Divider(color: Colors.white.withOpacity(0.1)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20)),
                    onPressed: () => Navigator.pop(context),
                    child: Text(t("CLOSE", widget.lang),
                        style: TextStyle(color: Colors.white)))
              ],
            ),
          ),
        );
      },
    );
  }
}

void _showSquadBuilder(BuildContext context, AppDatabase db, String lang) {
  showDialog(
    context: context,
    builder: (c) => _SquadBuilderDialog(database: db, lang: lang),
  );
}

class _SquadBuilderDialog extends StatefulWidget {
  final AppDatabase database;
  final String lang;
  const _SquadBuilderDialog({required this.database, required this.lang});

  @override
  State<_SquadBuilderDialog> createState() => _SquadBuilderDialogState();
}

class _SquadBuilderDialogState extends State<_SquadBuilderDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late TextEditingController _teamNameController;
  bool isVertical = true;
  String searchQuery = "";

  // 7 Pozisyon: 0:GK, 1:LCB, 2:RCB, 3:CAM, 4:LW, 5:RW, 6:ST
  List<Player?> squad = List.filled(7, null);

  @override
  void initState() {
    super.initState();
    _teamNameController =
        TextEditingController(text: t("TOTS_NAME", widget.lang));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D12),
      insetPadding: EdgeInsets.zero, // Full screen hissiyatı
      child: SizedBox(
        width: MediaQuery.of(context).size.width, // TAM EKRAN
        height: MediaQuery.of(context).size.height, // TAM EKRAN
        child: Row(
          children: [
            // --- SOL: SAHA VE KADRO ---
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Üst Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    color: Colors.black26,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _teamNameController,
                            style: GoogleFonts.russoOne(
                                color: Colors.white, fontSize: 24),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: t("TEAM_NAME", widget.lang),
                                hintStyle:
                                    const TextStyle(color: Colors.white24)),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                  isVertical
                                      ? Icons.stay_current_portrait
                                      : Icons.stay_current_landscape,
                                  color: Colors.white),
                              tooltip: t("ORIENT", widget.lang),
                              onPressed: () =>
                                  setState(() => isVertical = !isVertical),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _capture,
                              icon: const Icon(Icons.download,
                                  color: Colors.black),
                              label: Text(t("DOWNLOAD", widget.lang),
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context))
                          ],
                        )
                      ],
                    ),
                  ),
                  // Saha Alanı
                  Expanded(
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        // DÜZELTME: Sabit boyut yerine sonsuz boyut ile alanı dolduruyoruz
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF050505),
                                  Color(0xFF101025),
                                  Color(0xFF050505)
                                ]),
                            // Kenarlık inceltildi, radius kaldırıldı (Tam otursun diye)
                            border:
                                Border.all(color: Colors.white12, width: 2)),
                        child: Stack(
                          children: [
                            // Saha Çizgileri
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _PitchLinesPainter(
                                        isVertical: isVertical))),

                            // Takım İsmi
                            Positioned(
                                top: 20,
                                left: 0,
                                right: 0,
                                child: Center(
                                    child: ValueListenableBuilder<
                                            TextEditingValue>(
                                        valueListenable: _teamNameController,
                                        builder: (context, value, child) {
                                          return Text(value.text.toUpperCase(),
                                              style: GoogleFonts.russoOne(
                                                  color: Colors.white10,
                                                  fontSize: 80));
                                        }))),

                            // OYUNCU SLOTLARI VE NUMARALAR
                            // Kaleci (1)
                            _buildSlot(0, "GK", isVertical ? 0.5 : 0.1,
                                isVertical ? 0.88 : 0.5, 1),
                            // İlk Defans (3)
                            _buildSlot(1, "DEF", isVertical ? 0.3 : 0.25,
                                isVertical ? 0.72 : 0.3, 3),
                            // Yanındaki Defans (6)
                            _buildSlot(2, "DEF", isVertical ? 0.7 : 0.25,
                                isVertical ? 0.72 : 0.7, 6),
                            // Orta Saha (10)
                            _buildSlot(3, "CAM", isVertical ? 0.5 : 0.45,
                                isVertical ? 0.52 : 0.5, 10),
                            // Sol Kanat (7)
                            _buildSlot(4, "LW", isVertical ? 0.15 : 0.7,
                                isVertical ? 0.35 : 0.2, 7),
                            // Sağ Kanat (11)
                            _buildSlot(5, "RW", isVertical ? 0.85 : 0.7,
                                isVertical ? 0.35 : 0.8, 11),
                            // Forvet (9)
                            _buildSlot(6, "ST", isVertical ? 0.5 : 0.85,
                                isVertical ? 0.15 : 0.5, 9),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // --- SAĞ: OYUNCU HAVUZU ---
            Container(
              width: 350,
              color: const Color(0xFF101014),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: t("SEARCH", widget.lang),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.cyanAccent),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<dynamic>>(
                        stream: widget.database.watchAllPlayers(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                                child: CircularProgressIndicator());
                          // Basit convert
                          var list = snapshot.data!
                              .map((row) {
                                List<PlayStyle> ps = [];
                                try {
                                  var l =
                                      jsonDecode(row.playStylesJson) as List;
                                  ps = l.map((e) {
                                    String s = e.toString();
                                    return s.endsWith("+")
                                        ? PlayStyle(
                                            s.substring(0, s.length - 1),
                                            isGold: true)
                                        : PlayStyle(s, isGold: false);
                                  }).toList();
                                } catch (_) {}
                                return Player(
                                    name: row.name,
                                    rating: row.rating,
                                    position: row.position,
                                    playstyles: ps,
                                    cardType: row.cardType,
                                    team: row.team,
                                    stats: {},
                                    role: row.role ?? "Yok");
                              })
                              .where((p) => p.name
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()))
                              .toList();

                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10),
                            itemCount: list.length,
                            itemBuilder: (c, i) {
                              return Draggable<Player>(
                                data: list[i],
                                feedback: Material(
                                    color: Colors.transparent,
                                    child: SizedBox(
                                        width: 120,
                                        child:
                                            FCAnimatedCard(player: list[i]))),
                                child: FCAnimatedCard(
                                    player: list[i], animateOnHover: false),
                              );
                            },
                          );
                        }),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(
      int index, String label, double xAlign, double yAlign, int kitNumber) {
    // Align: 0.0 -> 1.0 arası. Stack içinde Positioned kullanacağız ama Alignment daha kolay.
    // Container boyutları (Saha): W:600/900, H:800/600
    // Kart Boyutu: W:130, H:180 (Büyük istendi)

    return Align(
      alignment: Alignment((xAlign * 2) - 1, (yAlign * 2) - 1),
      child: DragTarget<Player>(
        onAccept: (p) => setState(() => squad[index] = p),
        builder: (c, cand, rej) {
          Player? p = squad[index];
          return Container(
            width: 230, // KART ALANI DAHA DA BÜYÜTÜLDÜ
            height: 320, // NUMARA İÇİN YER AÇILDI
            decoration: BoxDecoration(
                // DÜZELTME: Kartlar daha belirgin olsun diye arka plan ve gölge
                color: p == null
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                boxShadow: p != null
                    ? [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2)
                      ]
                    : [],
                border: p == null
                    ? Border.all(color: Colors.white12, width: 2)
                    : Border.all(color: Colors.white24, width: 1)),
            child: p != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // FORMA NUMARASI
                      Text("$kitNumber",
                          style: GoogleFonts.russoOne(
                              fontSize: 32,
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                    color: Colors.black, blurRadius: 10)
                              ])),
                      const SizedBox(height: 5),
                      // KART
                      Expanded(
                        child: GestureDetector(
                            onTap: () => setState(
                                () => squad[index] = null), // Tıklayınca sil
                            child: FCAnimatedCard(
                                player: p, animateOnHover: true)),
                      ),
                    ],
                  )
                : Center(
                    child: Text(label,
                        style: GoogleFonts.russoOne(
                            color: Colors.white24, fontSize: 20))),
          );
        },
      ),
    );
  }

  void _capture() async {
    final image =
        await _screenshotController.capture(pixelRatio: 3.0); // Yüksek Kalite
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t("IMG_SAVED", widget.lang)),
          backgroundColor: Colors.green));
      // Burada dosya kaydetme işlemi yapılabilir (path_provider ile)
    }
  }
}

class _PitchLinesPainter extends CustomPainter {
  final bool isVertical;
  _PitchLinesPainter({required this.isVertical});
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    // Orta Çizgi
    if (isVertical)
      canvas.drawLine(
          Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    else
      canvas.drawLine(
          Offset(size.width / 2, 0), Offset(size.width / 2, size.height), p);
    // Orta Yuvarlak
    double radius = size.shortestSide * 0.15; // Dinamik yarıçap
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, p);
    // Ceza Sahaları (Basit)
    if (isVertical) {
      canvas.drawRect(
          Rect.fromLTWH(
              size.width * 0.2, 0, size.width * 0.6, size.height * 0.15),
          p);
      canvas.drawRect(
          Rect.fromLTWH(size.width * 0.2, size.height * 0.85, size.width * 0.6,
              size.height * 0.15),
          p);
    } else {
      canvas.drawRect(
          Rect.fromLTWH(
              0, size.height * 0.2, size.width * 0.15, size.height * 0.6),
          p);
      canvas.drawRect(
          Rect.fromLTWH(size.width * 0.85, size.height * 0.2, size.width * 0.15,
              size.height * 0.6),
          p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

void _showEditor(BuildContext context, Player? p,
    Function(Player, Player?) onSave, String lang) {
  showDialog(
      context: context,
      builder: (context) => CreatePlayerDialog(
          playerToEdit: p,
          lang: lang,
          onSave: (player) {
            if (player != null) onSave(player, p);
          }));
}

// ============================================================================
// BÖLÜM 5: CREATE PLAYER DIALOG (EKSİK OLAN PARÇA BURAYA EKLENDİ)
// ============================================================================

class CreatePlayerDialog extends StatefulWidget {
  final Player? playerToEdit;
  final Function(Player?) onSave;
  final bool isNewVersion;
  final String lang;

  const CreatePlayerDialog(
      {super.key,
      this.playerToEdit,
      required this.onSave,
      this.isNewVersion = false,
      required this.lang});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _teamController;
  late TextEditingController _ratingController;
  late TextEditingController _marketValueController;

  String selectedPosition = "(9) ST";
  String selectedCardType = "Temel";
  String selectedRole = "Avcı Forvet";
  int selectedSkillMoves = 3;
  int selectedWeakFoot = 3;
  String selectedChemistryStyle = "Basic";
  String selectedStyle = "Temel";
  int selectedStyleTier = 0; // 0, 1, 2
  List<PlayStyle> selectedPlayStyles = [];
  Map<String, int> stats = {};

  @override
  void initState() {
    super.initState();
    Player p = widget.playerToEdit ??
        Player(
            name: "",
            rating: 75,
            position: "(9) ST",
            playstyles: [],
            cardType: "Temel",
            team: "Takımsız");
    _nameController = TextEditingController(text: p.name);
    _teamController = TextEditingController(text: p.team);
    _ratingController = TextEditingController(text: p.rating.toString());
    // Market Value sadece sayı kısmını al
    String mvRaw = p.marketValue.replaceAll("€", "").replaceAll("M", "");
    _marketValueController = TextEditingController(text: mvRaw);

    selectedPosition = p.position;
    selectedCardType = p.cardType;
    selectedRole = p.role;
    selectedSkillMoves = p.skillMoves;
    selectedWeakFoot = p.stats['WF'] ?? 3;
    selectedChemistryStyle = p.chemistryStyle;
    selectedPlayStyles = List.from(p.playstyles);
    stats = Map<String, int>.from(p.stats);
    if (stats.isEmpty) {
      pd.statSegments.values.expand((e) => e).forEach((s) => stats[s] = 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E24),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        // DÜZELTME: Sabit boyut yerine ekran oranlı boyut (Pixel hatasını önler)
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
                widget.playerToEdit == null
                    ? t("CREATE_TITLE", widget.lang)
                    : t("EDIT_TITLE", widget.lang),
                style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 30),
            Expanded(
              child: Row(
                children: [
                  // SOL TARA - Temel Bilgiler
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _input(t("NAME", widget.lang), _nameController),
                          // TAKIM SEÇİMİ (DROPDOWN)
                          _dropdown(
                              t("TEAM", widget.lang),
                              pd.teamLogos.keys.toList(),
                              _teamController.text, (v) {
                            setState(() => _teamController.text = v!);
                          }),

                          _input(t("SORT_RTG", widget.lang), _ratingController,
                              isNum: true),
                          _dropdown(t("POS", widget.lang), pd.positions,
                              selectedPosition, (v) {
                            setState(() => selectedPosition = v!);
                            _checkGKStats(); // Pozisyon değişince statları güncelle
                            selectedStyle = "Temel"; // Stili sıfırla
                            // Pozisyona göre varsayılan rolü seç
                            // Burada basit bir mantık kurabilirsin
                          }),
                          _dropdown(t("CARD", widget.lang), pd.globalCardTypes,
                              selectedCardType, (v) {
                            setState(() => selectedCardType = v!);
                          }),
                          _dropdown(
                              t("ROLE", widget.lang),
                              roleDescriptions.keys.toList(),
                              selectedRole, (v) {
                            setState(() => selectedRole = v!);
                          }),
                          _dropdown(t("CHEM", widget.lang), chemistryStylesList,
                              selectedChemistryStyle, (v) {
                            setState(() => selectedChemistryStyle = v!);
                          }),
                          _input(
                              t("MARKET", widget.lang), _marketValueController,
                              isNum: true),

                          // YENİ: STİL SEÇİMİ
                          const SizedBox(height: 10),
                          Text(t("STYLE", widget.lang),
                              style: const TextStyle(color: Colors.cyanAccent)),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _getAvailableStyles()
                                          .contains(selectedStyle)
                                      ? selectedStyle
                                      : _getAvailableStyles().first,
                                  items: _getAvailableStyles()
                                      .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e,
                                              style: const TextStyle(
                                                  color: Colors.white))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => selectedStyle = v!),
                                  dropdownColor: const Color(0xFF2C2C35),
                                  decoration: InputDecoration(
                                      filled: true, fillColor: Colors.black26),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // TIER SEÇİMİ (+ / ++)
                              ToggleButtons(
                                isSelected: [
                                  selectedStyleTier == 0,
                                  selectedStyleTier == 1,
                                  selectedStyleTier == 2
                                ],
                                onPressed: (idx) =>
                                    setState(() => selectedStyleTier = idx),
                                color: Colors.white54,
                                selectedColor: Colors.cyanAccent,
                                fillColor: Colors.cyanAccent.withOpacity(0.2),
                                children: const [
                                  Text("-"),
                                  Text("+"),
                                  Text("++")
                                ],
                              )
                            ],
                          ),

                          // YETENEK VE ZAYIF AYAK
                          const SizedBox(height: 10),
                          Text(t("SKILL", widget.lang),
                              style: const TextStyle(color: Colors.amber)),
                          Row(
                            children: [
                              Expanded(
                                  child: Column(
                                children: [
                                  Text("SM: $selectedSkillMoves ⭐",
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  Slider(
                                      value: selectedSkillMoves.toDouble(),
                                      min: 1,
                                      max: 5,
                                      divisions: 4,
                                      activeColor: Colors.yellow,
                                      onChanged: (v) => setState(
                                          () => selectedSkillMoves = v.toInt()))
                                ],
                              )),
                              Expanded(
                                  child: Column(
                                children: [
                                  Text("WF: $selectedWeakFoot ⭐",
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  Slider(
                                      value: selectedWeakFoot.toDouble(),
                                      min: 1,
                                      max: 5,
                                      divisions: 4,
                                      activeColor: Colors.redAccent,
                                      onChanged: (v) => setState(
                                          () => selectedWeakFoot = v.toInt()))
                                ],
                              ))
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 40, color: Colors.white10),
                  // SAĞ TARAF - İstatistikler ve PlayStyle
                  Expanded(
                    flex: 2,
                    child: DefaultTabController(
                      length: 3, // Sekme sayısı 3 oldu
                      child: Column(
                        children: [
                          TabBar(
                            indicatorColor: Colors.cyanAccent,
                            tabs: [
                              Tab(text: t("STATS", widget.lang)),
                              Tab(text: t("NORMAL_PS", widget.lang)),
                              Tab(text: t("PLUS_PS", widget.lang)),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // TAB 1: İSTATİSTİKLER
                                SingleChildScrollView(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Wrap(
                                    spacing: 20,
                                    runSpacing: 20,
                                    children:
                                        pd.statSegments.entries.map((entry) {
                                      return Container(
                                        width: 250,
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(entry.key,
                                                style: const TextStyle(
                                                    color: Colors.amber,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 10),
                                            ...entry.value.map((s) => Row(
                                                  children: [
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text(s,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        12))),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Slider(
                                                        value: (stats[s] ?? 50)
                                                            .toDouble(),
                                                        min: 0,
                                                        max: 99,
                                                        activeColor:
                                                            Colors.cyanAccent,
                                                        inactiveColor:
                                                            Colors.white10,
                                                        onChanged: (v) =>
                                                            setState(() =>
                                                                stats[s] =
                                                                    v.toInt()),
                                                      ),
                                                    ),
                                                    Text("${stats[s] ?? 50}",
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))
                                                  ],
                                                ))
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                // TAB 2: NORMAL PLAYSTYLES
                                _buildPlayStyleSelector(isPlusMode: false),

                                // TAB 3: PLUS PLAYSTYLES
                                _buildPlayStyleSelector(isPlusMode: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t("CANCEL", widget.lang),
                        style: const TextStyle(color: Colors.white54))),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save, color: Colors.black),
                    label: Text(t("SAVE", widget.lang),
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15)))
              ],
            )
          ],
        ),
      ),
    );
  }

  // Pozisyona göre stil listesi
  List<String> _getAvailableStyles() {
    if (selectedPosition.contains("GK"))
      return ["Temel Kaleci", ...pd.styleOptions["GK"]!];
    if (selectedPosition.contains("CB"))
      return ["Temel Defans", ...pd.styleOptions["DEF"]!];
    if (selectedPosition.contains("CDM"))
      return ["Temel Defans", ...pd.styleOptions["DEF"]!]; // CDM de defansif
    if (selectedPosition.contains("CAM"))
      return ["Temel Orta Saha", ...pd.styleOptions["MID"]!];
    if (selectedPosition.contains("RW") || selectedPosition.contains("LW"))
      return ["Temel Kanat", ...pd.styleOptions["WING"]!];
    if (selectedPosition.contains("ST"))
      return ["Temel Forvet", ...pd.styleOptions["FWD"]!];
    return ["Temel"];
  }

  // GK ise statları değiştir
  void _checkGKStats() {
    if (selectedPosition.contains("GK")) {
      // GK Statlarını ekle
      for (var s in pd.gkStatsList) {
        if (!stats.containsKey(s)) stats[s] = 50;
      }
    }
  }

  // Gösterilecek stat listesi
  List<MapEntry<String, List<String>>> _getStatList() {
    if (selectedPosition.contains("GK")) {
      return [
        MapEntry("KALECİLİK", pd.gkStatsList),
        MapEntry("FİZİKSEL", ["Güç", "Sert Duruş", "Hız"]),
        MapEntry("ZİHİNSEL", ["Karar Alma", "Soğukkanlılık", "Liderlik"])
      ];
    }
    return pd.statSegments.entries.toList();
  }

  void _submit() {
    if (_nameController.text.isEmpty) return;

    // Zayıf ayağı stats içine gömüyoruz
    stats['WF'] = selectedWeakFoot;

    Player newP = Player(
        name: _nameController.text,
        rating: int.tryParse(_ratingController.text) ?? 75,
        position: selectedPosition,
        team: _teamController.text,
        cardType: selectedCardType,
        skillMoves: selectedSkillMoves,
        chemistryStyle: selectedChemistryStyle,
        marketValue: "€${_marketValueController.text}M", // Otomatik format
        playstyles: selectedPlayStyles,
        style: selectedStyle,
        styleTier: selectedStyleTier,
        stats: stats,
        role: selectedRole,
        recLink: widget.playerToEdit?.recLink ??
            "", // Eski veriyi koru (Maç geçmişi burada)
        manualGoals: widget.playerToEdit?.manualGoals ?? 0,
        manualAssists: widget.playerToEdit?.manualAssists ?? 0);

    widget.onSave(newP);
    Navigator.pop(context);
  }

  Widget _buildPlayStyleSelector({required bool isPlusMode}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: playStyleCategories.values.expand((e) => e).map((psData) {
          // Bu stil seçili mi?
          bool isSelected =
              selectedPlayStyles.any((p) => p.name == psData['name']);
          bool isGold = false;

          if (isSelected) {
            isGold = selectedPlayStyles
                .firstWhere((p) => p.name == psData['name'])
                .isGold;
          }

          // Eğer bu sekme Plus moduysa ve seçili olan Gold ise -> Aktif
          // Eğer bu sekme Normal modsa ve seçili olan Gold değilse -> Aktif
          bool isActiveInThisTab = isSelected && (isPlusMode == isGold);

          return GestureDetector(
            onTap: () {
              setState(() {
                // Önce var olanı kaldır (Toggle veya Değişim için)
                selectedPlayStyles.removeWhere((p) => p.name == psData['name']);

                // Eğer zaten bu modda seçiliyse kaldırdık, işlem bitti (Toggle Off)
                if (isActiveInThisTab) {
                  return;
                }

                // Değilse yeni halini ekle
                selectedPlayStyles
                    .add(PlayStyle(psData['name']!, isGold: isPlusMode));
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActiveInThisTab
                    ? (isPlusMode
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.cyanAccent.withOpacity(0.2))
                    : Colors.white10,
                border: Border.all(
                    color: isActiveInThisTab
                        ? (isPlusMode ? Colors.amber : Colors.cyanAccent)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActiveInThisTab)
                    Icon(isPlusMode ? Icons.star : Icons.check,
                        size: 14,
                        color: isPlusMode ? Colors.amber : Colors.cyanAccent),
                  const SizedBox(width: 5),
                  Text(psData['label']!,
                      style: TextStyle(
                          color:
                              isActiveInThisTab ? Colors.white : Colors.white54,
                          fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _input(String label, TextEditingController c, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String val,
      Function(String?) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: items.contains(val) ? val : items.first,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white))))
            .toList(),
        onChanged: onChange,
        dropdownColor: const Color(0xFF2C2C35),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
=======
>>>>>>> 8acca86af125de9036c7b4790addc68791c0e173
