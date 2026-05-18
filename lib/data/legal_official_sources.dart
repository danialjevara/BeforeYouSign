class OfficialLegalResourceSeed {
  const OfficialLegalResourceSeed({
    required this.name,
    required this.description,
    required this.website,
    this.phone,
  });

  final String name;
  final String description;
  final String website;
  final String? phone;
}

const Map<String, List<OfficialLegalResourceSeed>>
    legalOfficialResourcesByCountryCode = {
  'US': [
    OfficialLegalResourceSeed(
      name: 'Legal Services Corporation',
      description:
          'Federal legal-aid entry point with local program lookup across the United States.',
      website: 'https://www.lsc.gov/',
      phone: '+12022951500',
    ),
  ],
  'CA': [
    OfficialLegalResourceSeed(
      name: 'Association of Legal Aid Plans of Canada',
      description:
          'National directory hub for Canada’s provincial and territorial legal-aid plans.',
      website: 'https://alap-araj.ca/',
    ),
    OfficialLegalResourceSeed(
      name: 'Justice Canada Legal Aid Program',
      description:
          'Federal overview of Canada’s legal-aid framework and supported services.',
      website: 'https://www.justice.gc.ca/eng/fund-fina/gov-gouv/aid-aide/',
    ),
  ],
  'AU': [
    OfficialLegalResourceSeed(
      name: 'National Legal Aid',
      description:
          'National access point to Australia’s state and territory legal-aid commissions.',
      website: 'https://nationallegalaid.org.au/',
    ),
    OfficialLegalResourceSeed(
      name: 'Attorney-General’s Department legal assistance services',
      description:
          'Australian Government information on legal assistance, community legal centres, and related support.',
      website: 'https://www.ag.gov.au/legal-system/legal-assistance-services',
    ),
  ],
  'NZ': [
    OfficialLegalResourceSeed(
      name: 'New Zealand Ministry of Justice legal aid',
      description:
          'Official New Zealand guidance on eligibility, application steps, and legal-aid lawyers.',
      website:
          'https://www.justice.govt.nz/courts/going-to-court/legal-aid/get-legal-aid/',
    ),
  ],
  'GB': [
    OfficialLegalResourceSeed(
      name: 'GOV.UK Find a legal adviser',
      description:
          'Official government route to find a solicitor or lower-cost legal advice in England and Wales.',
      website: 'https://www.gov.uk/find-legal-advice/find-legal-adviser',
    ),
    OfficialLegalResourceSeed(
      name: 'GOV.UK Check legal aid',
      description:
          'Official service to check civil legal-aid eligibility in England and Wales.',
      website: 'https://www.gov.uk/check-legal-aid',
    ),
    OfficialLegalResourceSeed(
      name: 'mygov.scot legal aid',
      description:
          'Official Scottish government guidance on legal aid and legal-cost support in Scotland.',
      website: 'https://www.mygov.scot/legal-aid',
    ),
  ],
  'IE': [
    OfficialLegalResourceSeed(
      name: 'Legal Aid Board',
      description:
          'Official Irish civil legal-aid and law-centre service with application and contact details.',
      website: 'https://www.legalaidboard.ie/',
    ),
  ],
  'IN': [
    OfficialLegalResourceSeed(
      name: 'National Legal Services Authority',
      description:
          'Official free legal-services portal and legal-aid network for India.',
      website: 'https://nalsa.gov.in/legal-services/',
    ),
  ],
  'SG': [
    OfficialLegalResourceSeed(
      name: 'Legal Aid Bureau',
      description:
          'Official civil legal-aid service of Singapore’s Ministry of Law.',
      website: 'https://www.mlaw.gov.sg/about-us/what-we-do/legal-aid-bureau/',
    ),
    OfficialLegalResourceSeed(
      name: 'Legal Aid Bureau portal',
      description:
          'Applicant-facing official portal for Singapore legal-aid services and applications.',
      website: 'https://lab.mlaw.gov.sg/',
    ),
  ],
  'HK': [
    OfficialLegalResourceSeed(
      name: 'Legal Aid Department',
      description:
          'Official Hong Kong legal-aid overview, eligibility, and application guidance.',
      website: 'https://www.lad.gov.hk/eng/las/overview.html',
    ),
    OfficialLegalResourceSeed(
      name: 'GovHK legal advice and assistance',
      description:
          'Official Hong Kong government page explaining legal advice, legal aid, and related support.',
      website:
          'https://www.gov.hk/en/residents/government/legal/advice/advice.htm',
    ),
  ],
  'MY': [
    OfficialLegalResourceSeed(
      name: 'Legal Aid Department (Malaysia)',
      description:
          'Official government legal-aid department providing advice, litigation support, mediation, and related help.',
      website: 'https://jbg.spab.gov.my/eApps/system/index.do?aplCode=en',
    ),
    OfficialLegalResourceSeed(
      name: 'Malaysia.gov legal aid',
      description:
          'Official Malaysia government legal-aid information hub with service and eligibility guidance.',
      website:
          'https://www.malaysia.gov.my/en/categories/law--safety/legal-aid',
    ),
  ],
  'PH': [
    OfficialLegalResourceSeed(
      name: 'Public Attorney’s Office',
      description:
          'Official Philippine public legal-assistance office for eligible clients.',
      website: 'https://www.pao.gov.ph/',
    ),
  ],
  'ZA': [
    OfficialLegalResourceSeed(
      name: 'Legal Aid South Africa',
      description: 'Official national legal-aid service for South Africa.',
      website: 'https://www.legalaid.co.za/',
    ),
  ],
  'FI': [
    OfficialLegalResourceSeed(
      name: 'Oikeus.fi legal aid',
      description:
          'Official Finland legal-aid guidance covering public legal-aid attorneys and eligibility.',
      website:
          'https://www.oikeus.fi/en/themes/payment-difficulties-and-debt/legal-aid/',
    ),
  ],
  'DE': [
    OfficialLegalResourceSeed(
      name: 'Federal Bar nationwide lawyer directory',
      description:
          'Official nationwide lawyer register maintained by the German Federal Bar.',
      website:
          'https://www.brak.de/service/bundesweites-amtliches-anwaltsverzeichnis/',
    ),
    OfficialLegalResourceSeed(
      name: 'Federal Bar regional chambers',
      description:
          'Official directory of Germany’s regional bar chambers for jurisdiction-specific contact.',
      website: 'https://www.brak.de/die-brak/rechtsanwaltskammern/',
    ),
  ],
  'FR': [
    OfficialLegalResourceSeed(
      name: 'Service-Public legal aid',
      description:
          'Official French government legal-aid guidance for citizens and residents.',
      website:
          'https://www.service-public.gouv.fr/particuliers/vosdroits/F18074?lang=en',
    ),
  ],
  'ES': [
    OfficialLegalResourceSeed(
      name: 'Abogacia Española legal aid',
      description:
          'Official legal-profession resource on free legal assistance in Spain.',
      website: 'https://www.abogacia.es/en/areas-tematicas/justicia-gratuita/',
    ),
  ],
  'NL': [
    OfficialLegalResourceSeed(
      name: 'Het Juridisch Loket',
      description:
          'Official free first-line legal-information and referral service in the Netherlands.',
      website: 'https://www.juridischloket.nl/',
    ),
  ],
  'BE': [
    OfficialLegalResourceSeed(
      name: 'FPS Justice legal advice',
      description:
          'Official Belgian justice guidance on first-line and second-line legal help.',
      website: 'https://justice.belgium.be/fr/besoin_dun_avis_juridique',
    ),
    OfficialLegalResourceSeed(
      name: 'FPS Justice lawyer assistance',
      description:
          'Official Belgian justice page on obtaining a lawyer with free or reduced-fee support.',
      website:
          'https://justice.belgium.be/fr/que_faire_comme/cite/assistance_dun_avocat',
    ),
  ],
  'PL': [
    OfficialLegalResourceSeed(
      name: 'Gov.pl free legal aid',
      description: 'Official Polish free legal-aid and citizens-advice portal.',
      website: 'https://www.gov.pl/web/free-aid/unpaid-legal-help',
    ),
  ],
  'AT': [
    OfficialLegalResourceSeed(
      name: 'Austrian Bar lawyer finder',
      description:
          'Official Austrian Bar search tool for verified lawyers by region and specialty.',
      website:
          'https://www.oerak.at/en/support-and-services/services/find-a-lawyer/',
    ),
  ],
  'DK': [
    OfficialLegalResourceSeed(
      name: 'Danish Bar legal aid',
      description:
          'Official Danish Bar explanation of free and partially funded legal aid.',
      website:
          'https://www.advokatsamfundet.dk/english/find-a-lawyer/legal-aid/',
    ),
  ],
  'NO': [
    OfficialLegalResourceSeed(
      name: 'Norwegian Bar find-a-lawyer',
      description:
          'Official lawyer search service from the Norwegian Bar Association.',
      website:
          'https://www.advokatforeningen.no/en/about-advokatforeningen/search-for-members/',
    ),
  ],
  'SE': [
    OfficialLegalResourceSeed(
      name: 'Swedish Bar Association',
      description:
          'Official Swedish Bar entry point with lawyer-finder guidance.',
      website: 'https://www.advokatsamfundet.se/en/',
    ),
    OfficialLegalResourceSeed(
      name: 'Find a lawyer in Sweden',
      description:
          'Official Swedish Bar public-facing page for finding a lawyer.',
      website: 'https://www.advokatsamfundet.se/Anlita-en-advokat/',
    ),
  ],
  'PT': [
    OfficialLegalResourceSeed(
      name: 'Justica.gov.pt contact services',
      description:
          'Official Portuguese justice information line and contact points for justice services.',
      website: 'https://justica.gov.pt/en-gb/Servicos/Espaco-e-Linha-Justica',
      phone: '800910220',
    ),
    OfficialLegalResourceSeed(
      name: 'Access to law and judicial protection',
      description:
          'Official Portuguese justice-policy guidance on legal advice and legal aid.',
      website:
          'https://dgpj.justica.gov.pt/English/Alternative-Dispute-Resolution',
    ),
  ],
  'AE': [
    OfficialLegalResourceSeed(
      name: 'Abu Dhabi Judicial Department legal aid office',
      description:
          'Official Abu Dhabi legal-aid request and contact portal for court-connected support.',
      website:
          'https://www.adjd.gov.ae/sites/eServices/EN/Pages/LegalAidOffice.aspx',
    ),
    OfficialLegalResourceSeed(
      name: 'Dubai Legal Affairs lawyer directory',
      description:
          'Official directory of advocates and legal consultants published by the Government of Dubai.',
      website: 'https://legal.dubai.gov.ae/en/Services/Pages/directory.aspx',
    ),
  ],
  'QA': [
    OfficialLegalResourceSeed(
      name: 'QICDRC Legal Clinic',
      description:
          'Official Qatar legal-clinic access point for civil and commercial early legal help.',
      website: 'https://www.qicdrc.gov.qa/services/legal-clinic',
    ),
    OfficialLegalResourceSeed(
      name: 'Hukoomi useful numbers',
      description:
          'Official Qatar e-government directory for verified government and justice-related contacts.',
      website:
          'https://portal.www.gov.qa/wps/portal/labor/topicsEN/Important%20Contacts',
      phone: '+97444069999',
    ),
  ],
  'KW': [
    OfficialLegalResourceSeed(
      name: 'Kuwait Ministry of Justice',
      description:
          'Official justice-services portal with ministry procedures, locations, and information services.',
      website: 'https://www.moj.gov.kw/en/',
    ),
    OfficialLegalResourceSeed(
      name: 'Kuwait Ministry of Justice locations',
      description:
          'Official ministry-locations page for finding in-person justice service points in Kuwait.',
      website: 'https://www.moj.gov.kw/EN/Pages/Moj_loc.aspx',
    ),
  ],
  'BH': [
    OfficialLegalResourceSeed(
      name: 'Bahrain Legislation and Legal Opinion Commission',
      description:
          'Official Bahrain legal-information portal with government legal references and institutional links.',
      website: 'https://www.legalaffairs.gov.bh/en',
      phone: '+97317518000',
    ),
    OfficialLegalResourceSeed(
      name: 'Bahrain Ministry of Justice lawyer rosters',
      description:
          'Official Bahrain ministry publication listing registered lawyers before the courts.',
      website:
          'https://www.moj.gov.bh/images/pdf/Lawyers/court_of_cassation.pdf',
    ),
  ],
  'OM': [
    OfficialLegalResourceSeed(
      name: 'Oman Ministry of Justice and Legal Affairs',
      description:
          'Official Oman justice-and-legal-affairs portal with legislation, services, and ministry contacts.',
      website: 'https://www.mjla.gov.om/',
      phone: '+96824342357',
    ),
    OfficialLegalResourceSeed(
      name: 'Oman justice e-services guide',
      description:
          'Official e-services directory for judicial and legal-affairs services in Oman.',
      website: 'https://www.mjla.gov.om/pages/2',
    ),
  ],
  'SA': [
    OfficialLegalResourceSeed(
      name: 'Saudi Bar legal clinics',
      description:
          'Official legal-clinic and support information from the Saudi Bar Association.',
      website: 'https://sba.gov.sa/legal-clinics/',
      phone: '+966112403333',
    ),
    OfficialLegalResourceSeed(
      name: 'Saudi Bar legal establishments directory',
      description:
          'Official searchable directory of legal establishments and practitioners in Saudi Arabia.',
      website: 'https://sba.gov.sa/directorys-data/',
    ),
  ],
  'EG': [
    OfficialLegalResourceSeed(
      name: 'Egyptian Bar Association',
      description:
          'Official national bar portal with branch and service information in Egypt.',
      website: 'https://egyls.com/',
    ),
  ],
  'JO': [
    OfficialLegalResourceSeed(
      name: 'Jordan Ministry of Justice legal assistance directorate',
      description:
          'Official Jordanian Ministry of Justice page for the legal-assistance directorate.',
      website:
          'https://moj.gov.jo/EN/ListDetails/Directorates_and_Units/2313/9',
    ),
    OfficialLegalResourceSeed(
      name: 'Jordan legal aid system update',
      description:
          'Official Ministry of Justice page about the computerized legal-aid system and access-to-justice work.',
      website:
          'https://moj.gov.jo/En/NewsDetails/Launching_the_computerized_legal_aid_system',
    ),
  ],
  'BD': [
    OfficialLegalResourceSeed(
      name: 'National Legal Aid Services Organization',
      description:
          'Official Bangladesh government legal-aid portal with applications, helplines, and district offices.',
      website: 'https://nlaso.gov.bd/',
      phone: '16699',
    ),
    OfficialLegalResourceSeed(
      name: 'Supreme Court legal aid office',
      description:
          'Official Bangladesh Supreme Court legal-aid information page for higher-court assistance.',
      website:
          'https://www.supremecourt.gov.bd/web/index.php/web/img/resources/web/contents/legal_aid/indexn.php?menu=10&page=legal_aid.php',
    ),
  ],
  'LK': [
    OfficialLegalResourceSeed(
      name: 'Legal Aid Commission of Sri Lanka',
      description:
          'Official Sri Lanka legal-aid commission reference with nationwide centers and core contact details.',
      website:
          'https://www.moj.gov.lk/index.php?Itemid=179&catid=13&id=31%3Alegal-aid-commission-of-sri-lanka-ta&lang=en&option=com_content&view=article',
      phone: '+9411533529',
    ),
    OfficialLegalResourceSeed(
      name: 'Legal Aid Commission portal',
      description:
          'Official Sri Lanka legal-aid website. Availability may vary during maintenance windows.',
      website: 'https://legalaid.gov.lk/',
    ),
  ],
  'JP': [
    OfficialLegalResourceSeed(
      name: 'Japan Legal Support Center civil legal aid',
      description:
          'Official Houterasu guidance for civil legal aid, including multilingual support information.',
      website: 'https://www.houterasu.or.jp/site/english/civillegalaid.html',
      phone: '0570078377',
    ),
    OfficialLegalResourceSeed(
      name: 'Japan Legal Support Center overview',
      description:
          'Official overview of Houterasu services, mission, and office network across Japan.',
      website:
          'https://www.houterasu.or.jp/site/english/goalsandoperations.html',
    ),
  ],
  'KR': [
    OfficialLegalResourceSeed(
      name: 'Korea Legal Aid Corporation',
      description:
          'Official nationwide legal-aid and consultation service for Korea, including branch guidance.',
      website: 'https://www.klac.or.kr/lang/main.do',
      phone: '132',
    ),
    OfficialLegalResourceSeed(
      name: 'Korea legal-aid one-stop network',
      description:
          'Official linked-service portal for legal support and public-service coordination in Korea.',
      website: 'https://net.klac.or.kr/',
    ),
  ],
  'ID': [
    OfficialLegalResourceSeed(
      name: 'Indonesia legal aid portal',
      description:
          'Official Ministry of Law legal-aid portal covering consultation, Posbakum, and provider discovery.',
      website: 'https://bantuanhukum.bphn.go.id/',
    ),
    OfficialLegalResourceSeed(
      name: 'Cari OBH terdekat',
      description:
          'Official Indonesia map for nearby accredited legal-aid organizations and support posts.',
      website: 'https://bantuanhukum.bphn.go.id/obh-terdekat',
    ),
  ],
  'TH': [
    OfficialLegalResourceSeed(
      name: 'Lawyers Council of Thailand',
      description:
          'Official bar-council portal with verified lawyer access points and legal-advice hotline details.',
      website: 'https://lawyerscouncil.or.th/?lang=en',
      phone: '1167',
    ),
  ],
  'VN': [
    OfficialLegalResourceSeed(
      name: 'Vietnam legal aid portal',
      description:
          'Official Ministry of Justice legal-aid portal with hotline information and state legal-aid centers.',
      website: 'https://tgpl.moj.gov.vn/',
      phone: '02462739631',
    ),
    OfficialLegalResourceSeed(
      name: 'Vietnam legal-aid providers directory',
      description:
          'Official Vietnam legal-aid directory for organizations and accredited legal-aid providers.',
      website: 'https://dstrogiupphaply.moj.gov.vn',
    ),
  ],
  'TR': [
    OfficialLegalResourceSeed(
      name: 'Turkey legal aid guide',
      description:
          'Official English legal-aid guide explaining how bar-association legal-aid bureaus work in Turkiye.',
      website: 'https://adliyardim.adalet.gov.tr/index-english.html',
    ),
    OfficialLegalResourceSeed(
      name: 'Union of Turkish Bar Associations',
      description:
          'Official nationwide bar-association portal with verified contact information for local bar associations.',
      website:
          'https://www.barobirlik.org.tr/en/contact-informations-of-the-bar-associations',
      phone: '+903122925900',
    ),
  ],
  'MX': [
    OfficialLegalResourceSeed(
      name: 'Mexico federal public defense',
      description:
          'Official Mexican federal public-defense entry point for free legal orientation and representation.',
      website: 'https://www.gob.mx/defensapublica',
    ),
    OfficialLegalResourceSeed(
      name: 'IFDP Defensatel',
      description:
          'Official contact channel of the Instituto Federal de Defensoria Publica for remote assistance.',
      website: 'https://ifdpdefensatel.cjf.gob.mx/',
    ),
  ],
  'PE': [
    OfficialLegalResourceSeed(
      name: 'Peru public defense and access to justice',
      description:
          'Official MINJUSDH page for Peru public defense, free legal assistance, and district offices.',
      website:
          'https://www.gob.pe/11894-ministerio-de-justicia-y-derechos-humanos-direccion-general-de-defensa-publica-y-acceso-a-la-justicia',
      phone: '+5112048020',
    ),
    OfficialLegalResourceSeed(
      name: 'Peru Defensa Publica',
      description:
          'Official Peru public-defense access point for locating the nearest service office.',
      website: 'https://www.gob.pe/defensapublica',
    ),
  ],
  'AR': [
    OfficialLegalResourceSeed(
      name: 'Argentina Centros de Acceso a la Justicia',
      description:
          'Official nationwide legal-help network for free primary legal attention, referrals, and support.',
      website: 'https://www.argentina.gob.ar/justicia/afianzar/caj',
      phone: '137',
    ),
    OfficialLegalResourceSeed(
      name: 'Argentina Red Federal de Patrocinio Juridico Gratuito',
      description:
          'Official Argentina network for representation when a case needs court action beyond initial guidance.',
      website:
          'https://www.argentina.gob.ar/justicia/afianzar/caj/red-federal-de-patrocinio-juridico-gratuito-0',
    ),
  ],
  'CL': [
    OfficialLegalResourceSeed(
      name: 'ChileAtiende legal assistance',
      description:
          'Official Chile guidance for free legal orientation and representation through the CAJ network.',
      website:
          'https://www.chileatiende.gob.cl/fichas/17940-asistencia-juridica-profesional-y-gratuita',
      phone: '101',
    ),
    OfficialLegalResourceSeed(
      name: 'Chile Te Defiende',
      description:
          'Official Chile access-to-justice service rollout bringing together legal aid and victim defense.',
      website: 'https://accesoalajusticia.gob.cl/',
    ),
  ],
  'CO': [
    OfficialLegalResourceSeed(
      name: 'Colombia public defense',
      description:
          'Official Defensoria del Pueblo page for the national public-defense service in Colombia.',
      website: 'https://www.defensoria.gov.co/web/guest/defensoria-publica',
      phone: '018000914814',
    ),
  ],
  'BR': [
    OfficialLegalResourceSeed(
      name: 'Defensoria Publica da Uniao',
      description:
          'Official federal public-defense portal in Brazil with service access and regional units.',
      website: 'https://www.dpu.def.br/',
    ),
  ],
};
