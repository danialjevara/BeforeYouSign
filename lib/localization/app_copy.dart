import 'package:flutter/material.dart';

class AppCopy {
  AppCopy._(this.languageCode);

  static const String fallbackLanguageCode = 'en';
  static const List<String> supportedLanguageCodes = [
    'en',
    'es',
    'pt',
    'fr',
    'ar',
    'hi',
    'zh',
  ];
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('fr'),
    Locale('ar'),
    Locale('hi'),
    Locale('zh'),
  ];

  factory AppCopy.of(BuildContext context) {
    return AppCopy.forLocale(context.localeTag);
  }

  factory AppCopy.forLocale(String localeTag) {
    return AppCopy._(resolveLanguageCode(localeTag));
  }

  static String resolveLanguageCode(String localeTag) {
    final normalized = localeTag.toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh')) {
      return 'zh';
    }

    for (final code in supportedLanguageCodes) {
      if (normalized == code || normalized.startsWith('$code-')) {
        return code;
      }
    }

    return fallbackLanguageCode;
  }

  static Locale resolveLocale(Locale? deviceLocale) {
    if (deviceLocale == null) {
      return supportedLocales.first;
    }

    final resolvedLanguageCode = resolveLanguageCode(
      deviceLocale.toLanguageTag(),
    );
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == resolvedLanguageCode,
      orElse: () => supportedLocales.first,
    );
  }

  final String languageCode;

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'subtitle': 'Your local AI guardian against predatory documents.',
      'protect_my_signature': 'PROTECT MY SIGNATURE',
      'enable_full_ai': 'Set up Gemma 4 for full on-device analysis',
      'disclaimer':
          'Automated risk awareness only. Not legal advice. Consult an attorney.',
      'gemma_setup_title': 'Gemma 4 Setup',
      'gemma_setup_body':
          'Download Gemma 4 for accurate on-device analysis, or continue with a basic scan.',
      'use_app_now': 'Continue with limited scan',
      'download_gemma': 'Download Gemma 4',
      'keep_app_open': 'Keep the app open while the model downloads.',
      'back_to_app': 'Back to app',
      'gemma_ready': 'Gemma 4 is ready on this device.',
      'download_failed': 'Model download failed. Please try again.',
      'analysis_loading': 'Analyzing document...',
      'analysis_processing': 'Processing OCR text and user context',
      'analysis_complete': 'Analysis complete',
      'ocr_text': 'OCR Text',
      'context': 'Context',
      'provided': 'Provided',
      'dark_scenarios': '3 Dark Scenarios',
      'verdict_summary': 'Verdict Summary',
      'stop_audio': 'STOP AUDIO',
      'play_audio_verdict': 'PLAY AUDIO VERDICT',
      'connect_legal_help': 'Need Help? Connect with Legal Aid',
      'ai_risk_only': 'AI risk assessment only. Not legal advice.',
      'unknown_source': 'Unknown source',
      'private_analysis': '[Private On-Device Document Analysis]',
      'enable_gemma_short': 'Set up Gemma 4',
      'gemma_ready_short': 'Gemma 4 ready',
      'manual_text_needed': 'Manual text needed',
      'document_text': 'Document text',
      'retake': 'Retake',
      'edit_extracted': 'Edit the extracted text here',
      'capture_or_paste': 'Capture a document or paste its text here',
      'document_field_helper':
          'Keep this field honest. The analyzer will use exactly what is written here.',
      'stop': 'Stop',
      'speak': 'Speak',
      'context_hint': 'Explain why you are being asked to sign this document',
      'listening_helper':
          'Listening now. Speak naturally in the device language.',
      'type_or_tap_speak': 'Type the context or tap Speak to dictate it.',
      'type_instead': 'Type instead',
      'recapture': 'Recapture',
      'analyze_with_gemma': 'ANALYZE WITH GEMMA 4',
      'analyze_document': 'RUN LIMITED SAFETY SCAN',
      'point_camera': 'Point the camera at the document',
      'select_from_gallery': 'Select from gallery',
      'type_document_instead': 'Type document instead',
      'no_readable_text':
          'No readable text was extracted. Type the document text below.',
      'type_or_paste_continue':
          'Type or paste the document text below to continue.',
      'camera_not_ready':
          'Camera is not ready. You can type or paste the document.',
      'capture_failed':
          'Capture failed. You can still type or paste the document.',
      'add_document_text': 'Add document text before starting analysis.',
      'no_context_provided': 'No text or voice context provided.',
      'microphone_permission':
          'Microphone permission is required for voice input.',
      'speech_not_available':
          'Speech recognition is not available on this device.',
      'speech_could_not_start':
          'Could not start speech recognition on this device.',
      'loading_nearby_help': 'Loading nearby legal help...',
      'using_gps_live_data': 'Using GPS and live map data',
      'nearby_help_failed': 'Nearby legal help could not be loaded right now.',
      'try_again': 'Try again',
      'legal_help_info':
          'Results based on your location for direct contact.',
      'call_nearest_office': 'Call nearest office',
      'no_nearby_results': 'No nearby results found',
      'nearby_results': 'Nearby results',
      'no_legal_results':
          'No lawyer, notary, or courthouse results were found near the current location. Try again from another location.',
      'navigate': 'Navigate',
      'call': 'Call',
      'website': 'Website',
      'nearby_legal_help': 'Nearby Legal Help',
      'refresh': 'Refresh',
      'limited_offline': 'Limited offline safety scan',
      'full_analysis_completed': 'Full on-device analysis completed.',
      'gemma_not_installed':
          'Gemma 4 is not ready on this device yet, so this result comes from a limited local rules-based scan.',
      'gemma_could_not_finish':
          'Gemma 4 could not finish this analysis, so this result comes from a limited local rules-based scan.',
      'document_risk_assessment': 'Document risk assessment',
      'direct_liability': 'Direct liability',
      'hidden_obligation': 'Hidden obligation',
      'dispute_risk': 'Dispute risk',
      'review_risk': 'Review this risk carefully before signing.',
      'review_document':
          'This document should be reviewed carefully before signing.',
      'limited_risk': 'Limited risk signals detected',
      'moderate_risk': 'Moderate document risk detected',
      'high_risk': 'High-risk paperwork signals detected',
      'personal_liability': 'Personal liability',
      'personal_liability_guarantor':
          'You may be personally responsible for another\'s debt.',
      'personal_liability_generic':
          'May create direct personal liability upon breach.',
      'terms_change': 'Terms can change against you',
      'blank_spaces':
          'Blank spaces detected. Others could add obligations later.',
      'broad_clauses':
          'Vague clauses may be interpreted against you.',
      'asset_exposure': 'Money or asset exposure',
      'debt_signals':
          'Financial terms could expose your assets to risk.',
      'financial_disputes':
          'Unclear terms can trigger financial disputes.',
      'rules_summary':
          'Basic scan: Risks detected. Slow down and request clarification before signing.',
      'limited_offline_disclaimer':
          'Limited offline scan only. Not legal advice.',
      'lawyer': 'Lawyer',
      'notary': 'Notary',
      'court': 'Court',
      'legal_help': 'Legal help',
    },
    'es': {
      'subtitle': 'Tu guardián local con IA frente a documentos abusivos.',
      'protect_my_signature': 'PROTEGER MI FIRMA',
      'enable_full_ai':
          'Configurar Gemma 4 para el análisis completo en el dispositivo',
      'disclaimer':
          'Esta IA ofrece alertas de riesgo con fines educativos. No es asesoría legal. Las leyes varían. Consulta siempre a un abogado autorizado.',
      'gemma_setup_title': 'Configuración de Gemma 4',
      'gemma_setup_body':
          'Before You Sign está diseñado alrededor de Gemma 4 para analizar documentos de forma privada en el dispositivo. Puedes continuar ahora con un escaneo local limitado o descargar Gemma 4 para desbloquear la experiencia completa de análisis en este dispositivo.',
      'use_app_now': 'Continuar con escaneo limitado',
      'download_gemma': 'Descargar Gemma 4',
      'keep_app_open': 'Mantén la app abierta mientras se descarga el modelo.',
      'back_to_app': 'Volver a la app',
      'gemma_ready': 'Gemma 4 está lista en este dispositivo.',
      'download_failed': 'La descarga del modelo falló. Inténtalo de nuevo.',
      'analysis_loading': 'Analizando documento...',
      'analysis_processing':
          'Procesando el texto OCR y el contexto del usuario',
      'analysis_complete': 'Análisis completo',
      'ocr_text': 'Texto OCR',
      'context': 'Contexto',
      'provided': 'Disponible',
      'dark_scenarios': '3 escenarios de riesgo',
      'verdict_summary': 'Resumen del veredicto',
      'stop_audio': 'DETENER AUDIO',
      'play_audio_verdict': 'REPRODUCIR VEREDICTO',
      'connect_legal_help': '¿Necesitas ayuda? Conéctate con asistencia legal',
      'ai_risk_only': 'Solo evaluación de riesgo con IA. No es asesoría legal.',
      'unknown_source': 'Fuente desconocida',
      'private_analysis': '[Análisis privado del documento en el dispositivo]',
      'enable_gemma_short': 'Configurar Gemma 4',
      'gemma_ready_short': 'Gemma 4 lista',
      'manual_text_needed': 'Se necesita texto manual',
      'document_text': 'Texto del documento',
      'retake': 'Repetir',
      'edit_extracted': 'Edita aquí el texto extraído',
      'capture_or_paste': 'Captura un documento o pega su texto aquí',
      'document_field_helper':
          'Mantén este campo fiel al documento. El analizador usará exactamente lo que está escrito aquí.',
      'stop': 'Detener',
      'speak': 'Hablar',
      'context_hint': 'Explica por qué te están pidiendo firmar este documento',
      'listening_helper':
          'Escuchando ahora. Habla con naturalidad en el idioma del dispositivo.',
      'type_or_tap_speak': 'Escribe el contexto o toca Hablar para dictarlo.',
      'type_instead': 'Escribir en su lugar',
      'recapture': 'Capturar de nuevo',
      'analyze_with_gemma': 'ANALIZAR CON GEMMA 4',
      'analyze_document': 'EJECUTAR ESCANEO LIMITADO',
      'point_camera': 'Apunta la cámara al documento',
      'select_from_gallery': 'Seleccionar de la galería',
      'type_document_instead': 'Escribir el documento',
      'no_readable_text':
          'No se pudo extraer texto legible. Escribe el texto del documento abajo.',
      'type_or_paste_continue':
          'Escribe o pega abajo el texto del documento para continuar.',
      'camera_not_ready':
          'La cámara no está lista. Puedes escribir o pegar el documento.',
      'capture_failed':
          'La captura falló. Aun así puedes escribir o pegar el documento.',
      'add_document_text':
          'Agrega el texto del documento antes de iniciar el análisis.',
      'no_context_provided': 'No se proporcionó texto ni contexto de voz.',
      'microphone_permission':
          'Se requiere permiso del micrófono para la entrada por voz.',
      'speech_not_available':
          'El reconocimiento de voz no está disponible en este dispositivo.',
      'speech_could_not_start':
          'No se pudo iniciar el reconocimiento de voz en este dispositivo.',
      'loading_nearby_help': 'Cargando ayuda legal cercana...',
      'using_gps_live_data': 'Usando GPS y datos de mapa en vivo',
      'nearby_help_failed':
          'No se pudo cargar la ayuda legal cercana en este momento.',
      'try_again': 'Intentar de nuevo',
      'legal_help_info':
          'Estos resultados provienen de tu ubicación GPS actual y de datos de mapas en vivo. Úsalos para navegar, llamar o abrir el sitio web real de una oficina cuando esté disponible.',
      'call_nearest_office': 'Llamar a la oficina más cercana',
      'no_nearby_results': 'No se encontraron resultados cercanos',
      'nearby_results': 'Resultados cercanos',
      'no_legal_results':
          'No se encontraron abogados, notarios ni tribunales cerca de la ubicación actual. Intenta de nuevo desde otro lugar.',
      'navigate': 'Navegar',
      'call': 'Llamar',
      'website': 'Sitio web',
      'nearby_legal_help': 'Ayuda legal cercana',
      'refresh': 'Actualizar',
      'limited_offline': 'Escaneo de seguridad local limitado',
      'full_analysis_completed':
          'Se completó el análisis completo en el dispositivo.',
      'gemma_not_installed':
          'Gemma 4 aún no está lista en este dispositivo, así que este resultado proviene de un escaneo local limitado basado en reglas.',
      'gemma_could_not_finish':
          'Gemma 4 no pudo completar este análisis, así que este resultado proviene de un escaneo local limitado basado en reglas.',
      'document_risk_assessment': 'Evaluación de riesgo del documento',
      'direct_liability': 'Responsabilidad directa',
      'hidden_obligation': 'Obligación oculta',
      'dispute_risk': 'Riesgo de disputa',
      'review_risk': 'Revisa este riesgo cuidadosamente antes de firmar.',
      'review_document':
          'Este documento debe revisarse cuidadosamente antes de firmarlo.',
      'limited_risk': 'Se detectaron señales de riesgo limitadas',
      'moderate_risk': 'Se detectó un riesgo moderado en el documento',
      'high_risk': 'Se detectaron señales de alto riesgo en el documento',
      'personal_liability': 'Responsabilidad personal',
      'personal_liability_guarantor':
          'El lenguaje sugiere que podrías ser personalmente responsable de la obligación de otra persona.',
      'personal_liability_generic':
          'El documento puede crear responsabilidad personal directa si la otra parte alega un incumplimiento.',
      'terms_change': 'Los términos pueden cambiar en tu contra',
      'blank_spaces':
          'Se detectaron espacios en blanco. Eso puede permitir que alguien agregue montos, fechas u obligaciones después.',
      'broad_clauses':
          'Algunas cláusulas parecen lo bastante amplias o vagas como para interpretarse en tu contra más adelante.',
      'asset_exposure': 'Exposición de dinero o bienes',
      'debt_signals':
          'El texto contiene señales de deuda, pago o garantía que podrían poner en riesgo tu dinero, salario o propiedad.',
      'financial_disputes':
          'Incluso sin un lenguaje claro de deuda, firmar documentos poco claros puede provocar disputas financieras.',
      'rules_summary':
          'Este es un escaneo limitado basado en reglas, no una revisión completa con IA. Encontró suficientes señales para que avances con cautela, pidas una copia limpia y hagas preguntas aclaratorias antes de firmar.',
      'limited_offline_disclaimer':
          'Solo escaneo local limitado. No es asesoría legal.',
      'lawyer': 'Abogado',
      'notary': 'Notario',
      'court': 'Tribunal',
      'legal_help': 'Ayuda legal',
    },
    'pt': {
      'subtitle': 'Seu guardião local com IA contra documentos abusivos.',
      'protect_my_signature': 'PROTEGER MINHA ASSINATURA',
      'enable_full_ai':
          'Configurar o Gemma 4 para a análise completa no dispositivo',
      'disclaimer':
          'Esta IA oferece alertas de risco para fins educacionais. Não é aconselhamento jurídico. As leis variam. Consulte sempre um advogado habilitado.',
      'gemma_setup_title': 'Configuração do Gemma 4',
      'gemma_setup_body':
          'Before You Sign foi projetado em torno do Gemma 4 para analisar documentos de forma privada no dispositivo. Você pode continuar agora com uma verificação local limitada ou baixar o Gemma 4 para desbloquear a experiência completa de análise neste dispositivo.',
      'use_app_now': 'Continuar com verificação limitada',
      'download_gemma': 'Baixar Gemma 4',
      'keep_app_open': 'Mantenha o app aberto enquanto o modelo é baixado.',
      'back_to_app': 'Voltar ao app',
      'gemma_ready': 'Gemma 4 está pronta neste dispositivo.',
      'download_failed': 'Falha ao baixar o modelo. Tente novamente.',
      'analysis_loading': 'Analisando documento...',
      'analysis_processing': 'Processando o texto OCR e o contexto do usuário',
      'analysis_complete': 'Análise concluída',
      'ocr_text': 'Texto OCR',
      'context': 'Contexto',
      'provided': 'Disponível',
      'dark_scenarios': '3 cenários de risco',
      'verdict_summary': 'Resumo do veredito',
      'stop_audio': 'PARAR ÁUDIO',
      'play_audio_verdict': 'REPRODUZIR VEREDITO',
      'connect_legal_help':
          'Precisa de ajuda? Conecte-se à assistência jurídica',
      'ai_risk_only':
          'Somente avaliação de risco por IA. Não é aconselhamento jurídico.',
      'unknown_source': 'Fonte desconhecida',
      'private_analysis': '[Análise privada do documento no dispositivo]',
      'enable_gemma_short': 'Configurar Gemma 4',
      'gemma_ready_short': 'Gemma 4 pronta',
      'manual_text_needed': 'Texto manual necessário',
      'document_text': 'Texto do documento',
      'retake': 'Refazer',
      'edit_extracted': 'Edite aqui o texto extraído',
      'capture_or_paste': 'Capture um documento ou cole o texto aqui',
      'document_field_helper':
          'Mantenha este campo fiel ao documento. O analisador usará exatamente o que está escrito aqui.',
      'stop': 'Parar',
      'speak': 'Falar',
      'context_hint':
          'Explique por que estão pedindo que você assine este documento',
      'listening_helper':
          'Ouvindo agora. Fale naturalmente no idioma do dispositivo.',
      'type_or_tap_speak': 'Digite o contexto ou toque em Falar para ditar.',
      'type_instead': 'Digitar em vez disso',
      'recapture': 'Capturar de novo',
      'analyze_with_gemma': 'ANALISAR COM GEMMA 4',
      'analyze_document': 'EXECUTAR VERIFICAÇÃO LIMITADA',
      'point_camera': 'Aponte a câmera para o documento',
      'select_from_gallery': 'Selecionar da galeria',
      'type_document_instead': 'Digitar o documento',
      'no_readable_text':
          'Nenhum texto legível foi extraído. Digite abaixo o texto do documento.',
      'type_or_paste_continue':
          'Digite ou cole abaixo o texto do documento para continuar.',
      'camera_not_ready':
          'A câmera não está pronta. Você pode digitar ou colar o documento.',
      'capture_failed':
          'A captura falhou. Ainda assim você pode digitar ou colar o documento.',
      'add_document_text':
          'Adicione o texto do documento antes de iniciar a análise.',
      'no_context_provided': 'Nenhum texto ou contexto de voz foi fornecido.',
      'microphone_permission':
          'A permissão do microfone é necessária para a entrada por voz.',
      'speech_not_available':
          'O reconhecimento de fala não está disponível neste dispositivo.',
      'speech_could_not_start':
          'Não foi possível iniciar o reconhecimento de fala neste dispositivo.',
      'loading_nearby_help': 'Carregando ajuda jurídica próxima...',
      'using_gps_live_data': 'Usando GPS e dados de mapa em tempo real',
      'nearby_help_failed':
          'Não foi possível carregar a ajuda jurídica próxima agora.',
      'try_again': 'Tentar novamente',
      'legal_help_info':
          'Esses resultados vêm da sua localização atual via GPS e de dados de mapa em tempo real. Use-os para navegar, ligar ou abrir o site real do escritório quando disponível.',
      'call_nearest_office': 'Ligar para o escritório mais próximo',
      'no_nearby_results': 'Nenhum resultado próximo encontrado',
      'nearby_results': 'Resultados próximos',
      'no_legal_results':
          'Nenhum advogado, cartório ou tribunal foi encontrado perto da localização atual. Tente novamente de outro lugar.',
      'navigate': 'Navegar',
      'call': 'Ligar',
      'website': 'Site',
      'nearby_legal_help': 'Ajuda jurídica próxima',
      'refresh': 'Atualizar',
      'limited_offline': 'Verificação local limitada',
      'full_analysis_completed':
          'A análise completa no dispositivo foi concluída.',
      'gemma_not_installed':
          'O Gemma 4 ainda não está pronto neste dispositivo, então este resultado vem de uma verificação local limitada baseada em regras.',
      'gemma_could_not_finish':
          'O Gemma 4 não conseguiu concluir esta análise, então este resultado vem de uma verificação local limitada baseada em regras.',
      'document_risk_assessment': 'Avaliação de risco do documento',
      'direct_liability': 'Responsabilidade direta',
      'hidden_obligation': 'Obrigação oculta',
      'dispute_risk': 'Risco de disputa',
      'review_risk': 'Revise este risco com cuidado antes de assinar.',
      'review_document':
          'Este documento deve ser revisado com cuidado antes da assinatura.',
      'limited_risk': 'Sinais limitados de risco detectados',
      'moderate_risk': 'Risco moderado detectado no documento',
      'high_risk': 'Sinais de alto risco detectados no documento',
      'personal_liability': 'Responsabilidade pessoal',
      'personal_liability_guarantor':
          'A linguagem sugere que você pode ser pessoalmente responsável pela obrigação de outra pessoa.',
      'personal_liability_generic':
          'O documento pode criar responsabilidade pessoal direta se a outra parte alegar descumprimento.',
      'terms_change': 'Os termos podem mudar contra você',
      'blank_spaces':
          'Foram detectados espaços em branco. Isso pode permitir que alguém adicione valores, datas ou obrigações depois.',
      'broad_clauses':
          'Algumas cláusulas parecem amplas ou vagas o suficiente para serem interpretadas contra você mais tarde.',
      'asset_exposure': 'Exposição financeira ou patrimonial',
      'debt_signals':
          'O texto contém sinais de dívida, pagamento ou garantia que podem colocar seu dinheiro, salário ou bens em risco.',
      'financial_disputes':
          'Mesmo sem linguagem clara de dívida, assinar documentos pouco claros pode gerar disputas financeiras.',
      'rules_summary':
          'Esta é uma verificação limitada baseada em regras, não uma revisão completa por IA. Ela encontrou sinais suficientes para que você avance com cautela, peça uma cópia limpa e faça perguntas esclarecedoras antes de assinar.',
      'limited_offline_disclaimer':
          'Apenas verificação local limitada. Não é aconselhamento jurídico.',
      'lawyer': 'Advogado',
      'notary': 'Cartório',
      'court': 'Tribunal',
      'legal_help': 'Ajuda jurídica',
    },
    'fr': {
      'subtitle': 'Votre garde-fou IA local contre les documents abusifs.',
      'protect_my_signature': 'PROTEGER MA SIGNATURE',
      'enable_full_ai':
          'Configurer Gemma 4 pour l\'analyse complète sur l\'appareil',
      'disclaimer':
          'Cette IA fournit des alertes de risque à des fins éducatives. Elle ne constitue pas un conseil juridique. Les lois varient. Consultez toujours un avocat habilité.',
      'gemma_setup_title': 'Configuration de Gemma 4',
      'gemma_setup_body':
          'Before You Sign est conçu autour de Gemma 4 pour analyser les documents de façon privée sur l\'appareil. Vous pouvez continuer maintenant avec une vérification locale limitée ou télécharger Gemma 4 pour débloquer l\'expérience d\'analyse complète sur cet appareil.',
      'use_app_now': 'Continuer avec une vérification limitée',
      'download_gemma': 'Télécharger Gemma 4',
      'keep_app_open':
          'Gardez l\'application ouverte pendant le téléchargement du modèle.',
      'back_to_app': 'Retour à l\'application',
      'gemma_ready': 'Gemma 4 est prête sur cet appareil.',
      'download_failed': 'Le téléchargement du modèle a échoué. Réessayez.',
      'analysis_loading': 'Analyse du document...',
      'analysis_processing':
          'Traitement du texte OCR et du contexte utilisateur',
      'analysis_complete': 'Analyse terminée',
      'ocr_text': 'Texte OCR',
      'context': 'Contexte',
      'provided': 'Disponible',
      'dark_scenarios': '3 scénarios de risque',
      'verdict_summary': 'Résumé du verdict',
      'stop_audio': 'ARRÊTER L\'AUDIO',
      'play_audio_verdict': 'LIRE LE VERDICT',
      'connect_legal_help':
          'Besoin d\'aide ? Connectez-vous à l\'aide juridique',
      'ai_risk_only':
          'Évaluation du risque par IA uniquement. Pas un conseil juridique.',
      'unknown_source': 'Source inconnue',
      'private_analysis': '[Analyse privée du document sur l\'appareil]',
      'enable_gemma_short': 'Configurer Gemma 4',
      'gemma_ready_short': 'Gemma 4 prête',
      'manual_text_needed': 'Texte manuel nécessaire',
      'document_text': 'Texte du document',
      'retake': 'Reprendre',
      'edit_extracted': 'Modifiez ici le texte extrait',
      'capture_or_paste': 'Capturez un document ou collez son texte ici',
      'document_field_helper':
          'Gardez ce champ fidèle au document. L\'analyseur utilisera exactement ce qui est écrit ici.',
      'stop': 'Arrêter',
      'speak': 'Parler',
      'context_hint':
          'Expliquez pourquoi on vous demande de signer ce document',
      'listening_helper':
          'Écoute en cours. Parlez naturellement dans la langue de l\'appareil.',
      'type_or_tap_speak':
          'Saisissez le contexte ou touchez Parler pour le dicter.',
      'type_instead': 'Saisir à la place',
      'recapture': 'Recapturer',
      'analyze_with_gemma': 'ANALYSER AVEC GEMMA 4',
      'analyze_document': 'LANCER LA VÉRIFICATION LIMITÉE',
      'point_camera': 'Pointez la caméra vers le document',
      'select_from_gallery': 'Sélectionner depuis la galerie',
      'type_document_instead': 'Saisir le document',
      'no_readable_text':
          'Aucun texte lisible n\'a été extrait. Saisissez le texte du document ci-dessous.',
      'type_or_paste_continue':
          'Saisissez ou collez le texte du document ci-dessous pour continuer.',
      'camera_not_ready':
          'La caméra n\'est pas prête. Vous pouvez saisir ou coller le document.',
      'capture_failed':
          'La capture a échoué. Vous pouvez quand même saisir ou coller le document.',
      'add_document_text':
          'Ajoutez le texte du document avant de lancer l\'analyse.',
      'no_context_provided': 'Aucun texte ni contexte vocal n\'a été fourni.',
      'microphone_permission':
          'L\'autorisation du microphone est requise pour l\'entrée vocale.',
      'speech_not_available':
          'La reconnaissance vocale n\'est pas disponible sur cet appareil.',
      'speech_could_not_start':
          'Impossible de démarrer la reconnaissance vocale sur cet appareil.',
      'loading_nearby_help': 'Chargement de l\'aide juridique à proximité...',
      'using_gps_live_data':
          'Utilisation du GPS et de données cartographiques en direct',
      'nearby_help_failed':
          'L\'aide juridique à proximité n\'a pas pu être chargée pour le moment.',
      'try_again': 'Réessayer',
      'legal_help_info':
          'Ces résultats proviennent de votre position GPS actuelle et de données cartographiques en direct. Utilisez-les pour vous y rendre, appeler ou ouvrir le vrai site web d\'un bureau lorsqu\'il est disponible.',
      'call_nearest_office': 'Appeler le bureau le plus proche',
      'no_nearby_results': 'Aucun résultat proche trouvé',
      'nearby_results': 'Résultats proches',
      'no_legal_results':
          'Aucun avocat, notaire ou tribunal n\'a été trouvé près de la position actuelle. Réessayez depuis un autre endroit.',
      'navigate': 'Naviguer',
      'call': 'Appeler',
      'website': 'Site web',
      'nearby_legal_help': 'Aide juridique à proximité',
      'refresh': 'Actualiser',
      'limited_offline': 'Vérification locale limitée',
      'full_analysis_completed':
          'L\'analyse complète sur l\'appareil est terminée.',
      'gemma_not_installed':
          'Gemma 4 n\'est pas encore prête sur cet appareil, donc ce résultat vient d\'une vérification locale limitée basée sur des règles.',
      'gemma_could_not_finish':
          'Gemma 4 n\'a pas pu terminer cette analyse, donc ce résultat vient d\'une vérification locale limitée basée sur des règles.',
      'document_risk_assessment': 'Évaluation du risque du document',
      'direct_liability': 'Responsabilité directe',
      'hidden_obligation': 'Obligation cachée',
      'dispute_risk': 'Risque de litige',
      'review_risk': 'Examinez ce risque avec attention avant de signer.',
      'review_document':
          'Ce document doit être examiné avec attention avant la signature.',
      'limited_risk': 'Signaux de risque limités détectés',
      'moderate_risk': 'Risque modéré détecté dans le document',
      'high_risk': 'Signaux de risque élevé détectés dans le document',
      'personal_liability': 'Responsabilité personnelle',
      'personal_liability_guarantor':
          'Le langage suggère que vous pourriez être personnellement responsable de l\'obligation d\'une autre personne.',
      'personal_liability_generic':
          'Le document peut créer une responsabilité personnelle directe si l\'autre partie invoque un manquement.',
      'terms_change': 'Les conditions peuvent changer contre vous',
      'blank_spaces':
          'Des espaces vides ont été détectés. Cela peut permettre à quelqu\'un d\'ajouter plus tard des montants, des dates ou des obligations.',
      'broad_clauses':
          'Certaines clauses paraissent assez larges ou vagues pour être interprétées contre vous plus tard.',
      'asset_exposure': 'Exposition financière ou patrimoniale',
      'debt_signals':
          'Le texte contient des signaux de dette, de remboursement ou de garantie qui pourraient exposer votre argent, votre salaire ou vos biens.',
      'financial_disputes':
          'Même sans langage explicite sur la dette, signer des documents flous peut déclencher des litiges financiers.',
      'rules_summary':
          'Il s\'agit d\'une vérification limitée basée sur des règles, et non d\'une revue IA complète. Elle a trouvé suffisamment de signaux pour que vous avanciez prudemment, demandiez une copie propre et posiez des questions de clarification avant de signer.',
      'limited_offline_disclaimer':
          'Vérification locale limitée uniquement. Pas un conseil juridique.',
      'lawyer': 'Avocat',
      'notary': 'Notaire',
      'court': 'Tribunal',
      'legal_help': 'Aide juridique',
    },
    'ar': {
      'subtitle': 'حارس ذكاء اصطناعي محلي ضد المستندات الاستغلالية.',
      'protect_my_signature': 'احم توقيعي',
      'enable_full_ai': 'أعدّ Gemma 4 للتحليل الكامل على الجهاز',
      'disclaimer':
          'تنبيه آلي للمخاطر، وليس استشارة قانونية. استشر محامياً.',
      'gemma_setup_title': 'إعداد Gemma 4',
      'gemma_setup_body':
          'حمّل Gemma 4 لتحليل دقيق ومحمي على جهازك، أو تابع بفحص مبدئي سريع.',
      'use_app_now': 'تابع بالفحص المحدود',
      'download_gemma': 'نزّل Gemma 4',
      'keep_app_open': 'اترك التطبيق مفتوحًا أثناء تنزيل الموديل.',
      'back_to_app': 'العودة للتطبيق',
      'gemma_ready': 'Gemma 4 جاهز على هذا الجهاز.',
      'download_failed': 'فشل تنزيل الموديل. حاول مرة أخرى.',
      'analysis_loading': 'جارٍ تحليل المستند...',
      'analysis_processing': 'جارٍ معالجة نص OCR وسياق المستخدم',
      'analysis_complete': 'اكتمل التحليل',
      'ocr_text': 'نص OCR',
      'context': 'السياق',
      'provided': 'موجود',
      'dark_scenarios': '3 سيناريوهات خطيرة',
      'verdict_summary': 'ملخص النتيجة',
      'stop_audio': 'إيقاف الصوت',
      'play_audio_verdict': 'تشغيل النتيجة صوتيًا',
      'connect_legal_help': 'تحتاج مساعدة؟ اعرض المساعدة القانونية القريبة',
      'ai_risk_only': 'تقييم مخاطر بالذكاء الاصطناعي فقط. ليس استشارة قانونية.',
      'unknown_source': 'مصدر غير معروف',
      'private_analysis': '[تحليل خاص على الجهاز]',
      'enable_gemma_short': 'أعدّ Gemma 4',
      'gemma_ready_short': 'Gemma 4 جاهز',
      'manual_text_needed': 'أدخل النص يدويًا',
      'document_text': 'نص المستند',
      'retake': 'إعادة الالتقاط',
      'edit_extracted': 'عدّل النص المستخرج هنا',
      'capture_or_paste': 'التقط مستندًا أو الصق نصه هنا',
      'document_field_helper': 'التقييم سيعتمد على النص الموجود هنا حرفيًا.',
      'stop': 'إيقاف',
      'speak': 'تحدث',
      'context_hint': 'اشرح لماذا يُطلب منك توقيع هذا المستند',
      'listening_helper': 'جارٍ الاستماع الآن. تحدث بلغة الجهاز بشكل طبيعي.',
      'type_or_tap_speak': 'اكتب السياق أو اضغط تحدث للإملاء الصوتي.',
      'type_instead': 'اكتب بدلًا من ذلك',
      'recapture': 'التقاط جديد',
      'analyze_with_gemma': 'حلّل باستخدام Gemma 4',
      'analyze_document': 'شغّل الفحص المحدود',
      'point_camera': 'وجّه الكاميرا نحو المستند',
      'select_from_gallery': 'اختر من المعرض',
      'type_document_instead': 'اكتب المستند بدلًا من ذلك',
      'no_readable_text': 'لم يتم استخراج نص واضح. اكتب نص المستند بالأسفل.',
      'type_or_paste_continue': 'اكتب أو الصق نص المستند بالأسفل للمتابعة.',
      'camera_not_ready': 'الكاميرا غير جاهزة. يمكنك كتابة المستند أو لصقه.',
      'capture_failed': 'فشل الالتقاط. ما زال بإمكانك كتابة المستند أو لصقه.',
      'add_document_text': 'أضف نص المستند قبل بدء التحليل.',
      'no_context_provided': 'لم يتم تقديم سياق نصي أو صوتي.',
      'microphone_permission': 'مطلوب إذن الميكروفون للإدخال الصوتي.',
      'speech_not_available': 'التعرّف على الكلام غير متاح على هذا الجهاز.',
      'speech_could_not_start': 'تعذر بدء التعرّف على الكلام على هذا الجهاز.',
      'loading_nearby_help': 'جارٍ تحميل المساعدة القانونية القريبة...',
      'using_gps_live_data': 'باستخدام GPS وبيانات خريطة حية',
      'nearby_help_failed': 'تعذر تحميل المساعدة القانونية القريبة الآن.',
      'try_again': 'حاول مرة أخرى',
      'legal_help_info':
          'نتائج تقريبية حسب موقعك لتسهيل التواصل.',
      'call_nearest_office': 'اتصل بأقرب جهة',
      'no_nearby_results': 'لا توجد نتائج قريبة',
      'nearby_results': 'النتائج القريبة',
      'no_legal_results':
          'لم يتم العثور على محامٍ أو موثق أو محكمة بالقرب من موقعك الحالي. جرّب مرة أخرى من موقع آخر.',
      'navigate': 'تنقل',
      'call': 'اتصال',
      'website': 'الموقع',
      'nearby_legal_help': 'المساعدة القانونية القريبة',
      'refresh': 'تحديث',
      'limited_offline': 'فحص محلي محدود',
      'full_analysis_completed': 'اكتمل التحليل الكامل على الجهاز.',
      'gemma_not_installed':
          'Gemma 4 ليس جاهزًا بعد على هذا الجهاز، لذلك هذه النتيجة جاءت من فحص محلي محدود قائم على القواعد.',
      'gemma_could_not_finish':
          'لم يتمكن Gemma 4 من إكمال هذا التحليل، لذلك هذه النتيجة جاءت من فحص محلي محدود قائم على القواعد.',
      'document_risk_assessment': 'تقييم مخاطر المستند',
      'direct_liability': 'مسؤولية مباشرة',
      'hidden_obligation': 'التزام مخفي',
      'dispute_risk': 'خطر نزاع',
      'review_risk': 'راجع هذا الخطر بعناية قبل التوقيع.',
      'review_document': 'يجب مراجعة هذا المستند بعناية قبل التوقيع.',
      'limited_risk': 'تم رصد إشارات خطر محدودة',
      'moderate_risk': 'تم رصد مخاطر متوسطة في المستند',
      'high_risk': 'تم رصد إشارات خطر عالية في المستند',
      'personal_liability': 'مسؤولية شخصية',
      'personal_liability_guarantor':
          'احذر: قد تتحمل مسؤولية أو ديون شخص آخر.',
      'personal_liability_generic':
          'قد تتحمل مسؤولية شخصية مباشرة عند المخالفة.',
      'terms_change': 'قد تتغير الشروط ضدك',
      'blank_spaces':
          'فراغات تتيح إضافة التزامات أو مبالغ لاحقاً.',
      'broad_clauses': 'بنود غامضة قد تُفسر ضدك.',
      'asset_exposure': 'تعرض مالي أو على الأصول',
      'debt_signals':
          'شروط مالية قد تعرض أموالك أو ممتلكاتك للخطر.',
      'financial_disputes':
          'توقيع أوراق غامضة قد يسبب نزاعات مالية.',
      'rules_summary':
          'فحص مبدئي: توجد مخاطر. تمهّل واطلب توضيحاً قبل التوقيع.',
      'limited_offline_disclaimer': 'فحص محلي محدود فقط. ليس استشارة قانونية.',
      'lawyer': 'محام',
      'notary': 'موثق',
      'court': 'محكمة',
      'legal_help': 'مساعدة قانونية',
    },
    'hi': {
      'subtitle': 'शोषणकारी दस्तावेज़ों के खिलाफ आपका स्थानीय एआई सहायक।',
      'protect_my_signature': 'मेरे हस्ताक्षर सुरक्षित करें',
      'enable_full_ai': 'पूरे ऑन-डिवाइस विश्लेषण के लिए Gemma 4 सेट करें',
      'disclaimer':
          'यह एआई केवल जोखिम जागरूकता के लिए है, कानूनी सलाह नहीं। कानून अलग-अलग हो सकते हैं। जरूरत पड़ने पर लाइसेंस प्राप्त वकील से सलाह लें।',
      'gemma_setup_title': 'Gemma 4 सेटअप',
      'gemma_setup_body':
          'Before You Sign को निजी ऑन-डिवाइस दस्तावेज़ विश्लेषण के लिए Gemma 4 के आसपास बनाया गया है। आप अभी सीमित लोकल स्कैन के साथ आगे बढ़ सकते हैं, या इस डिवाइस पर पूरा विश्लेषण अनुभव खोलने के लिए Gemma 4 डाउनलोड कर सकते हैं।',
      'use_app_now': 'सीमित स्कैन के साथ जारी रखें',
      'download_gemma': 'Gemma 4 डाउनलोड करें',
      'keep_app_open': 'मॉडल डाउनलोड होने तक ऐप खुला रखें।',
      'back_to_app': 'ऐप पर वापस जाएं',
      'gemma_ready': 'Gemma 4 इस डिवाइस पर तैयार है।',
      'download_failed': 'मॉडल डाउनलोड विफल हुआ। फिर से कोशिश करें।',
      'analysis_loading': 'दस्तावेज़ का विश्लेषण हो रहा है...',
      'analysis_processing':
          'OCR टेक्स्ट और उपयोगकर्ता संदर्भ प्रोसेस हो रहा है',
      'analysis_complete': 'विश्लेषण पूरा',
      'ocr_text': 'OCR टेक्स्ट',
      'context': 'संदर्भ',
      'provided': 'दिया गया',
      'dark_scenarios': '3 जोखिम परिदृश्य',
      'verdict_summary': 'निष्कर्ष सारांश',
      'stop_audio': 'ऑडियो रोकें',
      'play_audio_verdict': 'ऑडियो निष्कर्ष चलाएँ',
      'connect_legal_help': 'मदद चाहिए? नज़दीकी कानूनी सहायता देखें',
      'ai_risk_only': 'केवल एआई जोखिम आकलन। कानूनी सलाह नहीं।',
      'unknown_source': 'अज्ञात स्रोत',
      'private_analysis': '[निजी ऑन-डिवाइस विश्लेषण]',
      'enable_gemma_short': 'Gemma 4 सेट करें',
      'gemma_ready_short': 'Gemma 4 तैयार',
      'manual_text_needed': 'मैन्युअल टेक्स्ट चाहिए',
      'document_text': 'दस्तावेज़ टेक्स्ट',
      'retake': 'फिर से लें',
      'edit_extracted': 'निकाला गया टेक्स्ट यहाँ संपादित करें',
      'capture_or_paste': 'दस्तावेज़ कैप्चर करें या टेक्स्ट यहाँ पेस्ट करें',
      'document_field_helper':
          'विश्लेषक ठीक वही टेक्स्ट इस्तेमाल करेगा जो यहाँ लिखा है।',
      'stop': 'रोकें',
      'speak': 'बोलें',
      'context_hint':
          'बताएं कि आपसे इस दस्तावेज़ पर हस्ताक्षर क्यों करवाए जा रहे हैं',
      'listening_helper':
          'अब सुन रहा है। डिवाइस भाषा में सामान्य रूप से बोलें।',
      'type_or_tap_speak':
          'संदर्भ टाइप करें या बोलकर लिखने के लिए बोलें दबाएं।',
      'type_instead': 'इसके बजाय टाइप करें',
      'recapture': 'फिर से कैप्चर करें',
      'analyze_with_gemma': 'Gemma 4 से विश्लेषण करें',
      'analyze_document': 'सीमित सुरक्षा स्कैन चलाएँ',
      'point_camera': 'कैमरा दस्तावेज़ की ओर रखें',
      'select_from_gallery': 'गैलरी से चुनें',
      'type_document_instead': 'दस्तावेज़ टाइप करें',
      'no_readable_text':
          'कोई पढ़ने योग्य टेक्स्ट नहीं मिला। नीचे दस्तावेज़ टेक्स्ट लिखें।',
      'type_or_paste_continue':
          'जारी रखने के लिए नीचे दस्तावेज़ टेक्स्ट टाइप या पेस्ट करें।',
      'camera_not_ready':
          'कैमरा तैयार नहीं है। आप दस्तावेज़ टाइप या पेस्ट कर सकते हैं।',
      'capture_failed':
          'कैप्चर विफल रहा। आप अभी भी दस्तावेज़ टाइप या पेस्ट कर सकते हैं।',
      'add_document_text':
          'विश्लेषण शुरू करने से पहले दस्तावेज़ टेक्स्ट जोड़ें।',
      'no_context_provided': 'कोई टेक्स्ट या वॉइस संदर्भ नहीं दिया गया।',
      'microphone_permission': 'वॉइस इनपुट के लिए माइक्रोफोन अनुमति आवश्यक है।',
      'speech_not_available': 'इस डिवाइस पर स्पीच रिकग्निशन उपलब्ध नहीं है।',
      'speech_could_not_start':
          'इस डिवाइस पर स्पीच रिकग्निशन शुरू नहीं हो सका।',
      'loading_nearby_help': 'नज़दीकी कानूनी सहायता लोड हो रही है...',
      'using_gps_live_data': 'GPS और लाइव मैप डेटा का उपयोग किया जा रहा है',
      'nearby_help_failed': 'अभी नज़दीकी कानूनी सहायता लोड नहीं हो सकी।',
      'try_again': 'फिर से कोशिश करें',
      'legal_help_info':
          'ये परिणाम आपकी वर्तमान GPS स्थिति और लाइव मैप डेटा से आते हैं। उपलब्ध होने पर आप इनसे नेविगेट, कॉल या वास्तविक वेबसाइट खोल सकते हैं।',
      'call_nearest_office': 'नज़दीकी कार्यालय को कॉल करें',
      'no_nearby_results': 'कोई नज़दीकी परिणाम नहीं मिला',
      'nearby_results': 'नज़दीकी परिणाम',
      'no_legal_results':
          'आपकी वर्तमान लोकेशन के पास कोई वकील, नोटरी या कोर्ट परिणाम नहीं मिला। किसी दूसरी लोकेशन से फिर प्रयास करें।',
      'navigate': 'नेविगेट करें',
      'call': 'कॉल',
      'website': 'वेबसाइट',
      'nearby_legal_help': 'नज़दीकी कानूनी सहायता',
      'refresh': 'रिफ्रेश',
      'limited_offline': 'सीमित ऑफलाइन स्कैन',
      'full_analysis_completed': 'पूरा ऑन-डिवाइस विश्लेषण पूरा हुआ।',
      'gemma_not_installed':
          'Gemma 4 अभी इस डिवाइस पर तैयार नहीं है, इसलिए यह परिणाम सीमित लोकल नियम-आधारित स्कैन से आया है।',
      'gemma_could_not_finish':
          'Gemma 4 यह विश्लेषण पूरा नहीं कर सका, इसलिए यह परिणाम सीमित लोकल नियम-आधारित स्कैन से आया है।',
      'document_risk_assessment': 'दस्तावेज़ जोखिम आकलन',
      'direct_liability': 'सीधी जिम्मेदारी',
      'hidden_obligation': 'छिपी हुई जिम्मेदारी',
      'dispute_risk': 'विवाद का जोखिम',
      'review_risk':
          'हस्ताक्षर करने से पहले इस जोखिम की सावधानी से समीक्षा करें।',
      'review_document':
          'हस्ताक्षर करने से पहले इस दस्तावेज़ की सावधानी से समीक्षा करें।',
      'limited_risk': 'सीमित जोखिम संकेत मिले',
      'moderate_risk': 'मध्यम दस्तावेज़ जोखिम मिला',
      'high_risk': 'उच्च जोखिम वाले दस्तावेज़ संकेत मिले',
      'personal_liability': 'व्यक्तिगत जिम्मेदारी',
      'personal_liability_guarantor':
          'भाषा से संकेत मिलता है कि आप किसी दूसरे व्यक्ति की जिम्मेदारी के लिए व्यक्तिगत रूप से उत्तरदायी हो सकते हैं।',
      'personal_liability_generic':
          'यदि दूसरी ओर से उल्लंघन का दावा किया जाता है तो यह दस्तावेज़ सीधे व्यक्तिगत दायित्व बना सकता है।',
      'terms_change': 'शर्तें आपके खिलाफ बदल सकती हैं',
      'blank_spaces':
          'खाली स्थान मिले हैं। इससे कोई बाद में राशि, तारीख या दायित्व जोड़ सकता है।',
      'broad_clauses':
          'कुछ धाराएँ इतनी व्यापक या अस्पष्ट हैं कि बाद में आपके खिलाफ व्याख्यायित की जा सकती हैं।',
      'asset_exposure': 'पैसे या संपत्ति का जोखिम',
      'debt_signals':
          'टेक्स्ट में कर्ज, भुगतान या गिरवी के संकेत हैं जो आपके पैसे, वेतन या संपत्ति को जोखिम में डाल सकते हैं।',
      'financial_disputes':
          'स्पष्ट कर्ज भाषा के बिना भी, अस्पष्ट कागज़ात पर हस्ताक्षर वित्तीय विवाद पैदा कर सकते हैं।',
      'rules_summary':
          'यह सीमित नियम-आधारित स्कैन है, पूरी एआई समीक्षा नहीं। इसमें ऐसे संकेत मिले हैं कि आपको रुककर साफ कॉपी मांगनी चाहिए और हस्ताक्षर से पहले स्पष्ट सवाल पूछने चाहिए।',
      'limited_offline_disclaimer':
          'केवल सीमित ऑफलाइन स्कैन। कानूनी सलाह नहीं।',
      'lawyer': 'वकील',
      'notary': 'नोटरी',
      'court': 'अदालत',
      'legal_help': 'कानूनी सहायता',
    },
    'zh': {
      'subtitle': '防范高风险文件的本地 AI 助手。',
      'protect_my_signature': '保护我的签名',
      'enable_full_ai': '设置 Gemma 4 以启用完整本地分析',
      'disclaimer': '此 AI 仅用于风险提示，不构成法律建议。法律因地区而异，必要时请咨询持牌律师。',
      'gemma_setup_title': 'Gemma 4 设置',
      'gemma_setup_body':
          'Before You Sign 围绕 Gemma 4 构建，用于在设备上私密分析文档。你现在可以继续使用有限的本地扫描，也可以下载 Gemma 4 以解锁此设备上的完整分析体验。',
      'use_app_now': '继续使用有限扫描',
      'download_gemma': '下载 Gemma 4',
      'keep_app_open': '模型下载期间请保持应用打开。',
      'back_to_app': '返回应用',
      'gemma_ready': 'Gemma 4 已在此设备上就绪。',
      'download_failed': '模型下载失败，请重试。',
      'analysis_loading': '正在分析文件...',
      'analysis_processing': '正在处理 OCR 文本和用户上下文',
      'analysis_complete': '分析完成',
      'ocr_text': 'OCR 文本',
      'context': '上下文',
      'provided': '已提供',
      'dark_scenarios': '3 个风险场景',
      'verdict_summary': '结论摘要',
      'stop_audio': '停止语音',
      'play_audio_verdict': '播放语音结论',
      'connect_legal_help': '需要帮助？查看附近法律帮助',
      'ai_risk_only': '仅为 AI 风险评估，不构成法律建议。',
      'unknown_source': '未知来源',
      'private_analysis': '[私密本地分析]',
      'enable_gemma_short': '设置 Gemma 4',
      'gemma_ready_short': 'Gemma 4 已就绪',
      'manual_text_needed': '需要手动输入文本',
      'document_text': '文件文本',
      'retake': '重新拍摄',
      'edit_extracted': '在此编辑提取出的文本',
      'capture_or_paste': '拍摄文件或在此粘贴文本',
      'document_field_helper': '分析器会严格使用此处的文本内容。',
      'stop': '停止',
      'speak': '说话',
      'context_hint': '说明为什么要求你签署这份文件',
      'listening_helper': '正在聆听。请用设备语言自然说话。',
      'type_or_tap_speak': '输入上下文，或点击“说话”进行语音输入。',
      'type_instead': '改为输入',
      'recapture': '重新拍摄',
      'analyze_with_gemma': '使用 Gemma 4 分析',
      'analyze_document': '运行有限安全扫描',
      'point_camera': '将摄像头对准文件',
      'select_from_gallery': '从相册选择',
      'type_document_instead': '改为输入文件内容',
      'no_readable_text': '未提取到可读文本，请在下方输入文件内容。',
      'type_or_paste_continue': '请在下方输入或粘贴文件文本以继续。',
      'camera_not_ready': '摄像头尚未就绪。你可以输入或粘贴文件内容。',
      'capture_failed': '拍摄失败。你仍然可以输入或粘贴文件内容。',
      'add_document_text': '开始分析前请先添加文件文本。',
      'no_context_provided': '未提供文本或语音上下文。',
      'microphone_permission': '语音输入需要麦克风权限。',
      'speech_not_available': '此设备不支持语音识别。',
      'speech_could_not_start': '无法在此设备上启动语音识别。',
      'loading_nearby_help': '正在加载附近法律帮助...',
      'using_gps_live_data': '正在使用 GPS 和实时地图数据',
      'nearby_help_failed': '暂时无法加载附近法律帮助。',
      'try_again': '重试',
      'legal_help_info': '这些结果来自你当前的 GPS 位置和实时地图数据。可在有数据时进行导航、拨号或打开真实网站。',
      'call_nearest_office': '拨打最近机构',
      'no_nearby_results': '未找到附近结果',
      'nearby_results': '附近结果',
      'no_legal_results': '在当前位置附近未找到律师、公证处或法院。请换个地点再试。',
      'navigate': '导航',
      'call': '拨打',
      'website': '网站',
      'nearby_legal_help': '附近法律帮助',
      'refresh': '刷新',
      'limited_offline': '有限离线扫描',
      'full_analysis_completed': '完整本地分析已完成。',
      'gemma_not_installed': 'Gemma 4 尚未在此设备上就绪，因此此结果来自有限的本地规则扫描。',
      'gemma_could_not_finish': 'Gemma 4 未能完成这次分析，因此此结果来自有限的本地规则扫描。',
      'document_risk_assessment': '文件风险评估',
      'direct_liability': '直接责任',
      'hidden_obligation': '隐藏义务',
      'dispute_risk': '争议风险',
      'review_risk': '签署前请认真审查此风险。',
      'review_document': '签署前应认真审查此文件。',
      'limited_risk': '检测到有限风险信号',
      'moderate_risk': '检测到中等文件风险',
      'high_risk': '检测到高风险文件信号',
      'personal_liability': '个人责任',
      'personal_liability_guarantor': '文中措辞表明你可能要为他人的义务承担个人责任。',
      'personal_liability_generic': '如果对方主张违约，此文件可能直接产生个人责任。',
      'terms_change': '条款可能会对你不利',
      'blank_spaces': '检测到空白处，后续可能被补填金额、日期或义务。',
      'broad_clauses': '某些条款过于宽泛或模糊，日后可能被解释为对你不利。',
      'asset_exposure': '资金或资产风险',
      'debt_signals': '文本包含债务、还款或担保信号，可能危及你的资金、工资或财产。',
      'financial_disputes': '即使没有明确债务措辞，签署不清晰文件也可能引发财务纠纷。',
      'rules_summary': '这是有限的规则扫描，而不是完整 AI 审核。结果表明你应当放慢节奏，索要清晰副本，并在签署前提出澄清问题。',
      'limited_offline_disclaimer': '仅限有限离线扫描，不构成法律建议。',
      'lawyer': '律师',
      'notary': '公证处',
      'court': '法院',
      'legal_help': '法律帮助',
    },
  };

  @visibleForTesting
  static Map<String, Map<String, String>> get debugStrings => _strings;

  String get subtitle => _t('subtitle');
  String get protectMySignature => _t('protect_my_signature');
  String get enableFullAi => _t('enable_full_ai');
  String get disclaimer => _t('disclaimer');
  String get gemmaSetupTitle => _t('gemma_setup_title');
  String get gemmaSetupBody => _t('gemma_setup_body');
  String get useAppNow => _t('use_app_now');
  String get downloadGemma => _t('download_gemma');
  String get keepAppOpen => _t('keep_app_open');
  String get backToApp => _t('back_to_app');
  String get gemmaReady => _t('gemma_ready');
  String get downloadFailed => _t('download_failed');
  String get analysisLoading => _t('analysis_loading');
  String get analysisProcessing => _t('analysis_processing');
  String get analysisComplete => _t('analysis_complete');
  String get ocrText => _t('ocr_text');
  String get context => _t('context');
  String get provided => _t('provided');
  String get darkScenarios => _t('dark_scenarios');
  String get verdictSummary => _t('verdict_summary');
  String get stopAudio => _t('stop_audio');
  String get playAudioVerdict => _t('play_audio_verdict');
  String get connectLegalHelp => _t('connect_legal_help');
  String get aiRiskOnly => _t('ai_risk_only');
  String get unknownSource => _t('unknown_source');
  String get privateAnalysis => _t('private_analysis');
  String get enableGemmaShort => _t('enable_gemma_short');
  String get gemmaReadyShort => _t('gemma_ready_short');
  String get manualTextNeeded => _t('manual_text_needed');
  String get documentText => _t('document_text');
  String get retake => _t('retake');
  String get editExtracted => _t('edit_extracted');
  String get captureOrPaste => _t('capture_or_paste');
  String get documentFieldHelper => _t('document_field_helper');
  String get stop => _t('stop');
  String get speak => _t('speak');
  String get contextHint => _t('context_hint');
  String get listeningHelper => _t('listening_helper');
  String get typeOrTapSpeak => _t('type_or_tap_speak');
  String get typeInstead => _t('type_instead');
  String get recapture => _t('recapture');
  String get analyzeWithGemma => _t('analyze_with_gemma');
  String get analyzeDocument => _t('analyze_document');
  String get pointCamera => _t('point_camera');
  String get selectFromGallery => _t('select_from_gallery');
  String get typeDocumentInstead => _t('type_document_instead');
  String get noReadableText => _t('no_readable_text');
  String get typeOrPasteContinue => _t('type_or_paste_continue');
  String get cameraNotReady => _t('camera_not_ready');
  String get captureFailed => _t('capture_failed');
  String get addDocumentText => _t('add_document_text');
  String get noContextProvided => _t('no_context_provided');
  String get microphonePermission => _t('microphone_permission');
  String get speechNotAvailable => _t('speech_not_available');
  String get speechCouldNotStart => _t('speech_could_not_start');
  String get loadingNearbyHelp => _t('loading_nearby_help');
  String get usingGpsLiveData => _t('using_gps_live_data');
  String get nearbyHelpFailed => _t('nearby_help_failed');
  String get tryAgain => _t('try_again');
  String get legalHelpInfo => _t('legal_help_info');
  String get callNearestOffice => _t('call_nearest_office');
  String get noNearbyResults => _t('no_nearby_results');
  String get nearbyResults => _t('nearby_results');
  String get noLegalResults => _t('no_legal_results');
  String get navigate => _t('navigate');
  String get call => _t('call');
  String get website => _t('website');
  String get nearbyLegalHelp => _t('nearby_legal_help');
  String get refresh => _t('refresh');
  String get limitedOffline => _t('limited_offline');
  String get fullAnalysisCompleted => _t('full_analysis_completed');
  String get gemmaNotInstalled => _t('gemma_not_installed');
  String get gemmaCouldNotFinish => _t('gemma_could_not_finish');
  String get documentRiskAssessment => _t('document_risk_assessment');
  String get directLiability => _t('direct_liability');
  String get hiddenObligation => _t('hidden_obligation');
  String get disputeRisk => _t('dispute_risk');
  String get reviewRisk => _t('review_risk');
  String get reviewDocument => _t('review_document');
  String get limitedRisk => _t('limited_risk');
  String get moderateRisk => _t('moderate_risk');
  String get highRisk => _t('high_risk');
  String get personalLiability => _t('personal_liability');
  String get personalLiabilityGuarantor => _t('personal_liability_guarantor');
  String get personalLiabilityGeneric => _t('personal_liability_generic');
  String get termsChange => _t('terms_change');
  String get blankSpaces => _t('blank_spaces');
  String get broadClauses => _t('broad_clauses');
  String get assetExposure => _t('asset_exposure');
  String get debtSignals => _t('debt_signals');
  String get financialDisputes => _t('financial_disputes');
  String get rulesSummary => _t('rules_summary');
  String get limitedOfflineDisclaimer => _t('limited_offline_disclaimer');

  String textReadyChars(int count) {
    return switch (languageCode) {
      'pt' => 'Texto pronto - $count caracteres',
      'fr' => 'Texte prêt - $count caractères',
      'es' => 'Texto listo - $count caracteres',
      'ar' => 'النص جاهز - $count حرف',
      'hi' => 'टेक्स्ट तैयार - $count अक्षर',
      'zh' => '文本已准备好 - $count 个字符',
      _ => 'Text ready - $count chars',
    };
  }

  String ocrChars(int count) {
    return switch (languageCode) {
      'pt' => '$count caracteres',
      'fr' => '$count caractères',
      'es' => '$count caracteres',
      'ar' => '$count حرف',
      'hi' => '$count अक्षर',
      'zh' => '$count 个字符',
      _ => '$count chars',
    };
  }

  String addTextManually(String message) {
    return switch (languageCode) {
      'pt' => '$message Adicione o texto manualmente abaixo.',
      'fr' => '$message Ajoutez le texte manuellement ci-dessous.',
      'es' => '$message Agrega el texto manualmente abajo.',
      'ar' => '$message أضف النص يدويًا بالأسفل.',
      'hi' => '$message नीचे टेक्स्ट मैन्युअली जोड़ें।',
      'zh' => '$message 请在下方手动补充文本。',
      _ => '$message Add the text manually below.',
    };
  }

  String scenarioSpoken(int index, String title, String description) {
    return switch (languageCode) {
      'pt' => 'Cenário $index. $title. $description',
      'fr' => 'Scénario $index. $title. $description',
      'es' => 'Escenario $index. $title. $description',
      'ar' => 'السيناريو $index. $title. $description',
      'hi' => 'परिदृश्य $index. $title. $description',
      'zh' => '场景 $index。$title。$description',
      _ => 'Scenario $index. $title. $description',
    };
  }

  String navigateToNearest(String category) {
    return switch (languageCode) {
      'pt' => 'Ir até o ${translateCategory(category)} mais próximo',
      'fr' => 'Aller vers le ${translateCategory(category)} le plus proche',
      'es' => 'Ir al ${translateCategory(category)} más cercano',
      'ar' => 'اتجه إلى أقرب ${translateCategory(category)}',
      'hi' => 'निकटतम ${translateCategory(category)} तक जाएँ',
      'zh' => '导航到最近的${translateCategory(category)}',
      _ => 'Navigate to nearest ${translateCategory(category)}',
    };
  }

  String kmAway(double km) {
    final value = km.toStringAsFixed(1);
    return switch (languageCode) {
      'pt' => 'A $value km',
      'fr' => 'À $value km',
      'es' => 'A $value km',
      'ar' => 'يبعد $value كم',
      'hi' => '$value किमी दूर',
      'zh' => '距离 $value 公里',
      _ => '$value km away',
    };
  }

  String translateCategory(String category) {
    return switch (category) {
      'Lawyer' => _t('lawyer'),
      'Legal aid' => legalAidLabel,
      'Bar association' => barAssociationLabel,
      'Notary' => _t('notary'),
      'Court' => _t('court'),
      _ => _t('legal_help'),
    };
  }

  String get legalAidLabel {
    return switch (languageCode) {
      'pt' => 'Ajuda jurídica',
      'fr' => 'Aide juridique',
      'es' => 'Asistencia legal',
      'ar' => 'مساعدة قانونية',
      'hi' => 'कानूनी सहायता',
      'zh' => '法律援助',
      _ => 'Legal aid',
    };
  }

  String get barAssociationLabel {
    return switch (languageCode) {
      'pt' => 'Ordem dos advogados',
      'fr' => 'Ordre des avocats',
      'es' => 'Colegio de abogados',
      'ar' => 'نقابة محامين',
      'hi' => 'बार एसोसिएशन',
      'zh' => '律师协会',
      _ => 'Bar association',
    };
  }

  String countryChip(String? countryName) {
    final label = countryName ?? areaLabel;
    return switch (languageCode) {
      'pt' => 'País: $label',
      'fr' => 'Pays : $label',
      'es' => 'País: $label',
      'ar' => 'البلد: $label',
      'hi' => 'देश: $label',
      'zh' => '国家：$label',
      _ => 'Country: $label',
    };
  }

  String legalHelpCountryNote(String? countryName) {
    final label = countryName ?? areaLabel;
    final focusIntro = switch (languageCode) {
      'pt' =>
        'A busca agora está ajustada para este país e prioriza a ajuda jurídica próxima mais relevante.',
      'fr' =>
        'La recherche est désormais adaptée à ce pays et priorise l’aide juridique de proximité la plus pertinente.',
      'es' =>
        'La búsqueda ya está ajustada para este país y prioriza la ayuda legal cercana más relevante.',
      'ar' =>
        'تم ضبط البحث على هذا البلد مع ترتيب أقرب الجهات القانونية الأنسب له.',
      'hi' =>
        'खोज इस देश के हिसाब से ट्यून की गई है और स्थानीय कानूनी मदद को प्राथमिकता देती है।',
      'zh' => '搜索已按这个国家进行调整，并优先显示更适合当地的法律帮助。',
      _ =>
        'Search is now tuned for this country and prioritizes the most relevant nearby legal help.',
    };
    return switch (languageCode) {
      'pt' => '$label. $focusIntro',
      'fr' => '$label. $focusIntro',
      'es' => '$label. $focusIntro',
      'ar' => '$label. $focusIntro',
      'hi' => '$label. $focusIntro',
      'zh' => '$label。$focusIntro',
      _ => '$label. $focusIntro',
    };
  }

  String countryAwareResultsTitle(String? countryName) {
    final label = countryName ?? areaLabel;
    return switch (languageCode) {
      'pt' => 'Resultados próximos em $label',
      'fr' => 'Résultats proches à $label',
      'es' => 'Resultados cercanos en $label',
      'ar' => 'نتائج قريبة في $label',
      'hi' => '$label में नज़दीकी परिणाम',
      'zh' => '$label 附近结果',
      _ => 'Nearby results in $label',
    };
  }

  String noLegalResultsForCountry(String? countryName) {
    final label = countryName ?? areaLabel;
    return switch (languageCode) {
      'pt' =>
        'Nenhum advogado, cartório, tribunal ou serviço de ajuda jurídica foi encontrado perto de $label. Tente atualizar a partir de outra localização.',
      'fr' =>
        'Aucun avocat, notaire, tribunal ou service d’aide juridique n’a été trouvé près de $label. Essayez d’actualiser depuis un autre emplacement.',
      'es' =>
        'No se encontraron abogados, notarios, tribunales ni ayuda legal cerca de $label. Intenta actualizar desde otra ubicación.',
      'ar' =>
        'لم يتم العثور على محامٍ أو موثق أو محكمة أو جهة مساعدة قانونية قرب $label. جرّب التحديث من موقع آخر.',
      'hi' =>
        '$label के आसपास कोई वकील, नोटरी, कोर्ट या कानूनी सहायता परिणाम नहीं मिला। किसी दूसरी लोकेशन से फिर प्रयास करें।',
      'zh' => '在 $label 附近未找到律师、公证处、法院或法律援助结果。请换个位置后重试。',
      _ =>
        'No lawyer, notary, court, or legal aid results were found near $label. Try refreshing from another location.',
    };
  }

  String get nearbyFallbackTitle {
    return switch (languageCode) {
      'pt' => 'Os resultados do mapa estão fracos agora',
      'fr' => 'Les résultats de la carte sont faibles pour le moment',
      'es' => 'Los resultados del mapa son débiles ahora',
      'ar' => 'نتائج الخريطة ضعيفة الآن',
      'hi' => 'मैप परिणाम अभी कमज़ोर हैं',
      'zh' => '地图结果目前较弱',
      _ => 'Map results are weak right now',
    };
  }

  String get nearbyFallbackHint {
    return switch (languageCode) {
      'pt' =>
        'Veja abaixo as fontes oficiais como próximo passo mais confiável.',
      'fr' =>
        'Consultez les sources officielles ci-dessous comme étape plus fiable.',
      'es' =>
        'Revisa las fuentes oficiales abajo como un siguiente paso más confiable.',
      'ar' => 'راجع المصادر الرسمية أدناه كخطوة أكثر موثوقية.',
      'hi' => 'अधिक भरोसेमंद अगले कदम के लिए नीचे दिए गए आधिकारिक स्रोत देखें।',
      'zh' => '请查看下方官方来源，作为更可靠的下一步。',
      _ => 'Check the official sources below for a more trusted next step.',
    };
  }

  String officialSourcesTitle(String? countryName) {
    final label = countryName ?? areaLabel;
    return switch (languageCode) {
      'pt' => 'Fontes oficiais em $label',
      'fr' => 'Sources officielles à $label',
      'es' => 'Fuentes oficiales en $label',
      'ar' => 'مصادر رسمية في $label',
      'hi' => '$label में आधिकारिक कानूनी स्रोत',
      'zh' => '$label 的官方法律资源',
      _ => 'Official legal sources in $label',
    };
  }

  String officialSourcesBody(bool isFallback) {
    return switch (languageCode) {
      'pt' => isFallback
          ? 'Quando os resultados do mapa estão fracos, aqui aparecem fontes oficiais mais confiáveis como próximo passo.'
          : 'Essas fontes oficiais acrescentam uma camada mais confiável ao lado dos resultados próximos.',
      'fr' => isFallback
          ? 'Lorsque les résultats de la carte sont faibles, des sources officielles plus fiables apparaissent ici comme prochaine étape.'
          : 'Ces sources officielles ajoutent une couche plus fiable aux côtés des résultats proches.',
      'es' => isFallback
          ? 'Cuando los resultados del mapa son débiles, aquí aparecen fuentes oficiales más confiables como siguiente paso.'
          : 'Estas fuentes oficiales añaden una capa más confiable junto a los resultados cercanos.',
      'ar' => isFallback
          ? 'عندما تكون نتائج الخريطة ضعيفة، تظهر هنا مصادر رسمية موثوقة كخطوة تالية.'
          : 'هذه مصادر رسمية إضافية تدعم النتائج القريبة.',
      'hi' => isFallback
          ? 'जब मैप परिणाम कमज़ोर हों, तो यहाँ अधिक भरोसेमंद आधिकारिक स्रोत दिखते हैं।'
          : 'ये अतिरिक्त आधिकारिक स्रोत पास के परिणामों को सपोर्ट करते हैं।',
      'zh' => isFallback ? '当地图结果较弱时，这里会显示更可信的官方法律资源。' : '这些官方法律资源可作为附近结果的补充。',
      _ => isFallback
          ? 'When map results are weak, these official sources offer a more trusted next step.'
          : 'These official sources add a more trusted layer beside the nearby results.',
    };
  }

  String get officialSourceHeader {
    return switch (languageCode) {
      'pt' => 'Fonte oficial',
      'fr' => 'Source officielle',
      'es' => 'Fuente oficial',
      'ar' => 'مصدر رسمي',
      'hi' => 'आधिकारिक स्रोत',
      'zh' => '官方来源',
      _ => 'Official source',
    };
  }

  String get officialSourceBadge {
    return switch (languageCode) {
      'pt' => 'Oficial',
      'fr' => 'Officiel',
      'es' => 'Oficial',
      'ar' => 'رسمي',
      'hi' => 'आधिकारिक',
      'zh' => '官方',
      _ => 'Official',
    };
  }

  String get openOfficialSite {
    return switch (languageCode) {
      'pt' => 'Abrir site oficial',
      'fr' => 'Ouvrir le site officiel',
      'es' => 'Abrir sitio oficial',
      'ar' => 'افتح الموقع الرسمي',
      'hi' => 'आधिकारिक साइट खोलें',
      'zh' => '打开官方网站',
      _ => 'Open official site',
    };
  }

  String get callOfficialLine {
    return switch (languageCode) {
      'pt' => 'Ligar para a linha oficial',
      'fr' => 'Appeler la ligne officielle',
      'es' => 'Llamar a la línea oficial',
      'ar' => 'اتصل بالجهة الرسمية',
      'hi' => 'आधिकारिक नंबर पर कॉल करें',
      'zh' => '拨打官方电话',
      _ => 'Call official line',
    };
  }

  String get legalUncertaintyWarning {
    return switch (languageCode) {
      'pt' =>
        'Aviso: o aplicativo pode errar ou ignorar detalhes jurídicos importantes. Ele não substitui um advogado habilitado.',
      'fr' =>
        'Avertissement : l’application peut se tromper ou manquer des détails juridiques importants. Elle ne remplace pas un avocat habilité.',
      'es' =>
        'Advertencia: la app puede equivocarse o pasar por alto detalles legales importantes. No sustituye a un abogado autorizado.',
      'ar' =>
        'تنبيه: التطبيق قد يخطئ في التحليل أو يفوت بنودًا مهمة. ليس بديلًا عن محامٍ مرخص.',
      'hi' =>
        'चेतावनी: यह ऐप गलत हो सकता है या कोई महत्वपूर्ण कानूनी बात छोड़ सकता है। यह लाइसेंस प्राप्त वकील का विकल्प नहीं है।',
      'zh' => '警告：这个应用可能出错，也可能漏掉重要法律细节。它不能代替执业律师。',
      _ =>
        'Warning: this app can be wrong or miss important legal details. It does not replace a licensed lawyer.',
    };
  }

  String get backgroundDownloadReady {
    return switch (languageCode) {
      'pt' =>
        'Você pode sair desta tela. O download continuará em segundo plano.',
      'fr' =>
        'Vous pouvez quitter cet écran. Le téléchargement continuera en arrière-plan.',
      'es' =>
        'Puedes salir de esta pantalla. La descarga continuará en segundo plano.',
      'ar' => 'يمكنك مغادرة هذه الصفحة وسيستمر التنزيل في الخلفية.',
      'hi' =>
        'आप इस स्क्रीन से बाहर जा सकते हैं। डाउनलोड बैकग्राउंड में जारी रहेगा।',
      'zh' => '你可以离开此页面，下载会在后台继续。',
      _ =>
        'You can leave this screen. The download will continue in the background.',
    };
  }

  String get backgroundDownloadResume {
    return switch (languageCode) {
      'pt' =>
        'Se a conexão cair, o app tentará continuar do progresso salvo em vez de recomeçar do zero.',
      'fr' =>
        'Si la connexion coupe, l’application essaiera de reprendre depuis la progression sauvegardée au lieu de recommencer.',
      'es' =>
        'Si la conexión se corta, la app intentará continuar desde el progreso guardado en lugar de empezar de cero.',
      'ar' =>
        'إذا انقطع الاتصال، سيحاول التطبيق استئناف التنزيل بدل البدء من الصفر.',
      'hi' =>
        'अगर कनेक्शन टूटे, तो ऐप शुरू से नहीं बल्कि सेव किए गए भाग से फिर कोशिश करेगा।',
      'zh' => '如果连接中断，应用会尽量从已保存的进度继续，而不是从头开始。',
      _ =>
        'If the connection drops, the app will try to continue from saved progress instead of starting over.',
    };
  }

  String get gemmaInstallingNow {
    return switch (languageCode) {
      'pt' => 'Preparando Gemma 4 neste dispositivo...',
      'fr' => 'Préparation de Gemma 4 sur cet appareil...',
      'es' => 'Preparando Gemma 4 en este dispositivo...',
      'ar' => 'جارٍ تجهيز Gemma 4 على هذا الجهاز...',
      'hi' => 'Gemma 4 को इस डिवाइस पर तैयार किया जा रहा है...',
      'zh' => '正在此设备上准备 Gemma 4...',
      _ => 'Preparing Gemma 4 on this device...',
    };
  }

  String get pauseDownload {
    return switch (languageCode) {
      'pt' => 'Pausar',
      'fr' => 'Mettre en pause',
      'es' => 'Pausar',
      'ar' => 'إيقاف مؤقت',
      'hi' => 'रोकें',
      'zh' => '暂停',
      _ => 'Pause',
    };
  }

  String get resumeDownload {
    return switch (languageCode) {
      'pt' => 'Retomar download',
      'fr' => 'Reprendre le téléchargement',
      'es' => 'Reanudar descarga',
      'ar' => 'استئناف التنزيل',
      'hi' => 'डाउनलोड फिर शुरू करें',
      'zh' => '继续下载',
      _ => 'Resume download',
    };
  }

  String get downloadPaused {
    return switch (languageCode) {
      'pt' => 'O download do Gemma 4 está em pausa.',
      'fr' => 'Le téléchargement de Gemma 4 est en pause.',
      'es' => 'La descarga de Gemma 4 está en pausa.',
      'ar' => 'تم إيقاف تنزيل Gemma 4 مؤقتًا.',
      'hi' => 'Gemma 4 डाउनलोड रुका हुआ है।',
      'zh' => 'Gemma 4 下载已暂停。',
      _ => 'Gemma 4 download is paused.',
    };
  }

  String get downloadReconnecting {
    return switch (languageCode) {
      'pt' => 'Conexão perdida. Retomando o download automaticamente…',
      'fr' => 'Connexion perdue. Reprise automatique du téléchargement…',
      'es' => 'Conexión perdida. Reanudando la descarga automáticamente…',
      'ar' => 'انقطع الاتصال. جارٍ استئناف التنزيل تلقائيًا…',
      'hi' => 'कनेक्शन टूटा। डाउनलोड अपने आप फिर शुरू हो रहा है…',
      'zh' => '连接中断，正在自动恢复下载…',
      _ => 'Connection lost. Resuming download automatically…',
    };
  }

  String get restartDownloadButton {
    return switch (languageCode) {
      'pt' => 'Reiniciar download do zero',
      'fr' => 'Redémarrer le téléchargement',
      'es' => 'Reiniciar descarga desde cero',
      'ar' => 'إعادة التنزيل من البداية',
      'hi' => 'डाउनलोड शुरू से शुरू करें',
      'zh' => '从头重新下载',
      _ => 'Restart download from scratch',
    };
  }

  String get restartDownloadTitle {
    return switch (languageCode) {
      'pt' => 'Reiniciar o download?',
      'fr' => 'Redémarrer le téléchargement ?',
      'es' => '¿Reiniciar la descarga?',
      'ar' => 'إعادة التنزيل من البداية؟',
      'hi' => 'डाउनलोड फिर शुरू करें?',
      'zh' => '重新开始下载？',
      _ => 'Restart download?',
    };
  }

  String get restartDownloadBody {
    return switch (languageCode) {
      'pt' =>
        'Isso vai apagar o progresso atual e baixar o modelo inteiro de novo. Tem certeza?',
      'fr' =>
        'Cela supprimera la progression actuelle et retéléchargera le modèle entier. Continuer ?',
      'es' =>
        'Esto eliminará el progreso actual y descargará el modelo completo de nuevo. ¿Continuar?',
      'ar' =>
        'سيتم حذف التقدم الحالي وإعادة تنزيل الموديل بالكامل. هل تريد المتابعة؟',
      'hi' =>
        'इससे मौजूदा प्रगति हट जाएगी और पूरा मॉडल फिर से डाउनलोड होगा। जारी रखें?',
      'zh' => '这会清除当前进度并重新下载整个模型。确定继续？',
      _ =>
        'This will discard the current progress and download the entire model again. Continue?',
    };
  }

  String get restartDownloadConfirm {
    return switch (languageCode) {
      'pt' => 'Sim, reiniciar',
      'fr' => 'Oui, redémarrer',
      'es' => 'Sí, reiniciar',
      'ar' => 'نعم، أعد التنزيل',
      'hi' => 'हाँ, फिर शुरू करें',
      'zh' => '是的，重新开始',
      _ => 'Yes, restart',
    };
  }

  String get cancelLabel {
    return switch (languageCode) {
      'pt' => 'Cancelar',
      'fr' => 'Annuler',
      'es' => 'Cancelar',
      'ar' => 'إلغاء',
      'hi' => 'रद्द करें',
      'zh' => '取消',
      _ => 'Cancel',
    };
  }

  String get modelPreparing {
    return switch (languageCode) {
      'pt' =>
        'O download foi concluído. Agora o arquivo final do modelo está sendo preparado.',
      'fr' =>
        'Le téléchargement est terminé. Le fichier final du modèle est en cours de préparation.',
      'es' =>
        'La descarga se completó. Ahora se está preparando el archivo final del modelo.',
      'ar' => 'جاري تجهيز الملف النهائي بعد اكتمال التنزيل.',
      'hi' => 'डाउनलोड पूरा हो गया है। अब अंतिम मॉडल तैयार किया जा रहा है।',
      'zh' => '下载已完成，正在准备最终模型文件。',
      _ =>
        'The download is complete. The final model file is being prepared now.',
    };
  }

  String downloadProgressDetail(String downloaded, String total) {
    return switch (languageCode) {
      'pt' => '$downloaded de $total MB',
      'fr' => '$downloaded sur $total MB',
      'es' => '$downloaded de $total MB',
      'ar' => '$downloaded من $total ميجابايت',
      'hi' => '$downloaded / $total MB',
      'zh' => '$downloaded / $total MB',
      _ => '$downloaded / $total MB',
    };
  }

  String downloadSpeedDetail(String speed) {
    return switch (languageCode) {
      'pt' => 'Velocidade atual: $speed MB/s',
      'fr' => 'Vitesse actuelle : $speed MB/s',
      'es' => 'Velocidad actual: $speed MB/s',
      'ar' => 'السرعة الحالية: $speed ميجابايت/ث',
      'hi' => 'वर्तमान गति: $speed MB/s',
      'zh' => '当前速度：$speed MB/s',
      _ => 'Current speed: $speed MB/s',
    };
  }

  String downloadRemainingDetail(String remaining) {
    return switch (languageCode) {
      'pt' => 'Tempo restante: $remaining',
      'fr' => 'Temps restant : $remaining',
      'es' => 'Tiempo restante: $remaining',
      'ar' => 'الوقت المتبقي: $remaining',
      'hi' => 'बाकी समय: $remaining',
      'zh' => '剩余时间：$remaining',
      _ => 'Time remaining: $remaining',
    };
  }

  String get gemmaSetupChecklistTitle {
    return switch (languageCode) {
      'pt' => 'Antes do download',
      'fr' => 'Avant le téléchargement',
      'es' => 'Antes de descargar',
      'ar' => 'قبل التنزيل',
      'hi' => 'डाउनलोड से पहले',
      'zh' => '下载前',
      _ => 'Before downloading',
    };
  }

  List<String> gemmaSetupChecklist({
    required String freeSpace,
    required String ram,
    required String modelSize,
  }) {
    return switch (languageCode) {
      'pt' => [
          'Before You Sign foi projetado em torno do Gemma 4. Se o modelo ainda não estiver pronto, você pode continuar com uma verificação local limitada.',
          'Reserve pelo menos $freeSpace de armazenamento livre.',
          'Para uma experiência mais estável, use um aparelho com $ram de RAM ou mais.',
          'Use uma rede estável porque o modelo tem cerca de $modelSize.',
        ],
      'fr' => [
          'Before You Sign est conçu autour de Gemma 4. Si le modèle n’est pas encore prêt, vous pouvez continuer avec une vérification locale limitée.',
          'Gardez au moins $freeSpace d’espace de stockage libre.',
          'Pour une expérience plus stable, utilisez un appareil avec $ram de RAM ou plus.',
          'Utilisez un réseau stable car le modèle pèse environ $modelSize.',
        ],
      'es' => [
          'Before You Sign está diseñado alrededor de Gemma 4. Si el modelo todavía no está listo, puedes continuar con un escaneo local limitado.',
          'Mantén al menos $freeSpace de almacenamiento libre.',
          'Para una experiencia más estable, usa un dispositivo con $ram de RAM o más.',
          'Usa una red estable porque el modelo pesa cerca de $modelSize.',
        ],
      'ar' => [
          'تم تصميم Before You Sign حول Gemma 4. وإذا لم يكن الموديل جاهزًا بعد، يمكنك المتابعة بفحص محلي محدود.',
          'يفضل وجود مساحة خالية لا تقل عن $freeSpace.',
          'لتجربة أكثر استقرارًا، استخدم هاتفًا بذاكرة $ram أو أكثر.',
          'استخدم شبكة مستقرة لأن حجم الموديل يقارب $modelSize.',
        ],
      'hi' => [
          'Before You Sign को Gemma 4 के आसपास बनाया गया है। अगर मॉडल अभी तैयार नहीं है، तब भी आप सीमित लोकल सुरक्षा स्कैन के साथ आगे बढ़ सकते हैं।',
          'कम से कम $freeSpace खाली स्टोरेज रखना बेहतर है।',
          'ज्यादा स्थिर अनुभव के लिए $ram RAM या उससे अधिक वाला डिवाइस इस्तेमाल करें।',
          'स्थिर नेटवर्क का उपयोग करें क्योंकि मॉडल लगभग $modelSize का है।',
        ],
      'zh' => [
          'Before You Sign 围绕 Gemma 4 构建。如果模型尚未就绪，你仍然可以继续使用有限的本地安全扫描。',
          '建议至少保留 $freeSpace 的可用存储空间。',
          '为了获得更稳定的体验，建议使用至少 $ram 内存的设备。',
          '模型大小约为 $modelSize，请尽量使用稳定网络。',
        ],
      _ => [
          'Before You Sign is designed around Gemma 4. If the model is not ready yet, you can still continue with a limited local safety scan.',
          'Keep at least $freeSpace of free storage.',
          'For a steadier experience, use a device with $ram of RAM or more.',
          'Use a stable network because the model is about $modelSize.',
        ],
    };
  }

  String get refreshStatus {
    return switch (languageCode) {
      'pt' => 'Atualizar status',
      'fr' => 'Actualiser l’état',
      'es' => 'Actualizar estado',
      'ar' => 'تحديث الحالة',
      'hi' => 'स्थिति रीफ़्रेश करें',
      'zh' => '刷新状态',
      _ => 'Refresh status',
    };
  }

  String gemmaDownloadStatusChip(int percentage) {
    return switch (languageCode) {
      'pt' => 'Gemma $percentage%',
      'fr' => 'Gemma $percentage%',
      'es' => 'Gemma $percentage%',
      'ar' => 'Gemma $percentage٪',
      'hi' => 'Gemma $percentage%',
      'zh' => 'Gemma $percentage%',
      _ => 'Gemma $percentage%',
    };
  }

  String get printedModeLabel {
    return switch (languageCode) {
      'pt' => 'Impresso',
      'fr' => 'Imprime',
      'es' => 'Impreso',
      'ar' => 'مطبوع',
      'hi' => 'प्रिंटेड',
      'zh' => '印刷体',
      _ => 'Printed',
    };
  }

  String get handwritingModeLabel {
    return switch (languageCode) {
      'pt' => 'Manuscrito',
      'fr' => 'Manuscrit',
      'es' => 'A mano',
      'ar' => 'يدوي',
      'hi' => 'हस्तलिखित',
      'zh' => '手写',
      _ => 'Handwriting',
    };
  }

  String get captureModePrintedHint {
    return switch (languageCode) {
      'pt' =>
        'Preencha o quadro com a página e mantenha os quatro cantos visíveis.',
      'fr' =>
        'Remplissez le cadre avec la page et gardez les quatre coins visibles.',
      'es' =>
        'Llena el cuadro con la página y mantén visibles las cuatro esquinas.',
      'ar' => 'اجعل الصفحة تملأ الإطار مع ظهور الزوايا الأربع بوضوح.',
      'hi' => 'पेज को फ्रेम में भरें और चारों कोने साफ़ दिखने दें।',
      'zh' => '让页面尽量填满画面，并保持四个角清晰可见。',
      _ => 'Fill the frame with the page and keep all four corners visible.',
    };
  }

  String get captureModeHandwritingHint {
    return switch (languageCode) {
      'pt' =>
        'Aproxime a escrita, evite sombras e mantenha o traço escuro e nítido.',
      'fr' =>
        'Rapprochez l’écriture, évitez les ombres et gardez l’encre sombre et nette.',
      'es' =>
        'Acerca más la escritura, evita sombras y procura que la tinta se vea oscura y nítida.',
      'ar' =>
        'قرّب الكتابة أكثر، وتجنب الظلال، واجعل الحبر داكنًا وواضحًا قدر الإمكان.',
      'hi' =>
        'हस्तलिखित हिस्से को और पास रखें, छाया से बचें, और लिखावट गहरी व साफ़ रखें।',
      'zh' => '让手写区域更靠近镜头，避免阴影，并尽量保持笔迹深而清晰。',
      _ =>
        'Move closer to the handwriting, avoid shadows, and keep the ink dark and sharp.',
    };
  }

  String get autoCropBadge {
    return switch (languageCode) {
      'pt' => 'Auto recorte',
      'fr' => 'Recadrage auto',
      'es' => 'Recorte auto',
      'ar' => 'قص تلقائي',
      'hi' => 'ऑटो क्रॉप',
      'zh' => '自动裁切',
      _ => 'Auto-cropped',
    };
  }

  String get autoCropNotice {
    return switch (languageCode) {
      'pt' =>
        'O app recortou a imagem automaticamente ao redor do texto detectado para melhorar a leitura.',
      'fr' =>
        'L’application a recadré automatiquement autour du texte détecté pour améliorer la lecture.',
      'es' =>
        'La app recortó automáticamente alrededor del texto detectado para mejorar la lectura.',
      'ar' => 'قصّ التطبيق الصورة تلقائيًا حول النص المكتشف لتحسين القراءة.',
      'hi' =>
        'पढ़ने की गुणवत्ता बेहतर करने के लिए ऐप ने पहचाने गए टेक्स्ट के आसपास चित्र को अपने आप क्रॉप किया।',
      'zh' => '应用已围绕检测到的文本自动裁切图像，以提升识别清晰度。',
      _ =>
        'The app auto-cropped around the detected text to improve readability.',
    };
  }

  String get areaLabel {
    return switch (languageCode) {
      'pt' => 'sua área',
      'fr' => 'votre zone',
      'es' => 'tu zona',
      'ar' => 'منطقتك',
      'hi' => 'आपका क्षेत्र',
      'zh' => '你所在区域',
      _ => 'your area',
    };
  }

  String get matchedTextLabel {
    return switch (languageCode) {
      'pt' => 'Trecho correspondente',
      'fr' => 'Texte correspondant',
      'es' => 'Texto coincidente',
      'ar' => 'النص المطابق',
      'hi' => 'मिला हुआ पाठ',
      'zh' => '匹配文本',
      _ => 'Matched text',
    };
  }

  String get documentClauseLabel {
    return switch (languageCode) {
      'pt' => 'Cláusula do documento',
      'fr' => 'Clause du document',
      'es' => 'Cláusula del documento',
      'ar' => 'البند من المستند',
      'hi' => 'दस्तावेज़ की धारा',
      'zh' => '文档中的条款',
      _ => 'Clause from the document',
    };
  }

  String get whyDangerousLabel {
    return switch (languageCode) {
      'pt' => 'Por que isso é perigoso',
      'fr' => 'Pourquoi c\'est dangereux',
      'es' => 'Por qué esto es peligroso',
      'ar' => 'لماذا هذا خطير',
      'hi' => 'यह खतरनाक क्यों है',
      'zh' => '为什么这很危险',
      _ => 'Why this is dangerous',
    };
  }

  String get primaryGemmaCta {
    return switch (languageCode) {
      'pt' => 'CONFIGURAR GEMMA 4',
      'fr' => 'CONFIGURER GEMMA 4',
      'es' => 'CONFIGURAR GEMMA 4',
      'ar' => 'جهّز GEMMA 4',
      'hi' => 'GEMMA 4 सेट करें',
      'zh' => '设置 GEMMA 4',
      _ => 'SET UP GEMMA 4',
    };
  }

  String get fullAnalysisRequiredTitle {
    return switch (languageCode) {
      'pt' => 'A análise completa usa Gemma 4',
      'fr' => 'L’analyse complète utilise Gemma 4',
      'es' => 'El análisis completo usa Gemma 4',
      'ar' => 'التحليل الكامل يعتمد على Gemma 4',
      'hi' => 'पूर्ण विश्लेषण Gemma 4 पर चलता है',
      'zh' => '完整分析依赖 Gemma 4',
      _ => 'Full analysis runs on Gemma 4',
    };
  }

  String get fullAnalysisRequiredBody {
    return switch (languageCode) {
      'pt' =>
        'Para a experiência principal de julgamento, instale o modelo primeiro. A verificação limitada fica disponível apenas como plano B explícito.',
      'fr' =>
        'Pour la démonstration principale, installez d’abord le modèle. Le scan limité reste disponible seulement comme plan B explicite.',
      'es' =>
        'Para la experiencia principal, instala primero el modelo. El escaneo limitado queda disponible solo como plan B explícito.',
      'ar' =>
        'لأفضل تجربة تحكيم، جهّز الموديل أولًا. الفحص المحدود ما زال متاحًا لكن كخطة بديلة صريحة فقط.',
      'hi' =>
        'मुख्य जजिंग अनुभव के लिए पहले मॉडल तैयार करें। सीमित स्कैन अब केवल साफ़ तौर पर चुना गया बैकअप है।',
      'zh' => '为了主展示体验，请先准备好模型。有限扫描仍然保留，但只作为明确选择的备选方案。',
      _ =>
        'For the primary judged experience, install the model first. The limited scan remains available only as an explicit backup path.',
    };
  }

  String get runLimitedScan {
    return switch (languageCode) {
      'pt' => 'Executar verificação limitada',
      'fr' => 'Lancer la vérification limitée',
      'es' => 'Ejecutar escaneo limitado',
      'ar' => 'شغّل الفحص المحدود',
      'hi' => 'सीमित स्कैन चलाएँ',
      'zh' => '运行有限扫描',
      _ => 'Run limited scan',
    };
  }

  String get questionToAskLabel {
    return switch (languageCode) {
      'pt' => 'Pergunta para fazer antes de assinar',
      'fr' => 'Question à poser avant de signer',
      'es' => 'Pregunta para hacer antes de firmar',
      'ar' => 'سؤال يجب طرحه قبل التوقيع',
      'hi' => 'साइन करने से पहले पूछने वाला सवाल',
      'zh' => '签字前要问的问题',
      _ => 'Question to ask before signing',
    };
  }

  String get askBeforeSigningTitle {
    return switch (languageCode) {
      'pt' => 'Perguntas antes de assinar',
      'fr' => 'Questions avant de signer',
      'es' => 'Preguntas antes de firmar',
      'ar' => 'أسئلة قبل التوقيع',
      'hi' => 'साइन करने से पहले के सवाल',
      'zh' => '签字前先问',
      _ => 'Ask before signing',
    };
  }

  String get saferNextStepTitle {
    return switch (languageCode) {
      'pt' => 'Próximo passo mais seguro',
      'fr' => 'Étape suivante la plus sûre',
      'es' => 'Próximo paso más seguro',
      'ar' => 'الخطوة الأكثر أمانًا',
      'hi' => 'सबसे सुरक्षित अगला कदम',
      'zh' => '更稳妥的下一步',
      _ => 'Safer next step',
    };
  }

  String get groundedEvidenceLabel {
    return switch (languageCode) {
      'pt' => 'Rastreamento do texto',
      'fr' => 'Ancrage du texte',
      'es' => 'Anclaje del texto',
      'ar' => 'تثبيت الدليل في النص',
      'hi' => 'टेक्स्ट ग्राउंडिंग',
      'zh' => '文本锚定',
      _ => 'Text grounding',
    };
  }

  String groundingStatus(int matched, int total) {
    return switch (languageCode) {
      'pt' => '$matched de $total cenários ancorados no documento ou contexto',
      'fr' =>
        '$matched sur $total scénarios ancrés dans le document ou le contexte',
      'es' =>
        '$matched de $total escenarios anclados en el documento o contexto',
      'ar' => '$matched من $total سيناريوهات مثبتة في المستند أو السياق',
      'hi' => '$matched / $total परिदृश्य दस्तावेज़ या संदर्भ में एंकर किए गए',
      'zh' => '$matched / $total 个场景已锚定到文档或上下文',
      _ => '$matched of $total scenarios anchored in the document or context',
    };
  }

  String translateEvidenceSource(String source) {
    return switch (source) {
      'document' => switch (languageCode) {
          'pt' => 'Documento',
          'fr' => 'Document',
          'es' => 'Documento',
          'ar' => 'من المستند',
          'hi' => 'दस्तावेज़',
          'zh' => '文档',
          _ => 'Document',
        },
      'context' => switch (languageCode) {
          'pt' => 'Contexto',
          'fr' => 'Contexte',
          'es' => 'Contexto',
          'ar' => 'من السياق',
          'hi' => 'संदर्भ',
          'zh' => '上下文',
          _ => 'Context',
        },
      'model' => switch (languageCode) {
          'pt' => 'Inferido',
          'fr' => 'Inféré',
          'es' => 'Inferido',
          'ar' => 'استدلال',
          'hi' => 'अनुमान',
          'zh' => '推断',
          _ => 'Inferred',
        },
      _ => switch (languageCode) {
          'pt' => 'Sem evidência',
          'fr' => 'Sans preuve',
          'es' => 'Sin evidencia',
          'ar' => 'بلا دليل',
          'hi' => 'कोई साक्ष्य नहीं',
          'zh' => '无证据',
          _ => 'No evidence',
        },
    };
  }

  String get storageStoredSecurely {
    return switch (languageCode) {
      'pt' => 'Resultado salvo com criptografia local neste aparelho.',
      'fr' => 'Résultat enregistré avec chiffrement local sur cet appareil.',
      'es' => 'Resultado guardado con cifrado local en este dispositivo.',
      'ar' => 'تم حفظ النتيجة محليًا مع تشفير على هذا الجهاز.',
      'hi' => 'परिणाम इस डिवाइस पर लोकल एन्क्रिप्शन के साथ सेव हुआ।',
      'zh' => '结果已在此设备上以本地加密方式保存。',
      _ => 'Result saved with local encryption on this device.',
    };
  }

  String get storageLocked {
    return switch (languageCode) {
      'pt' =>
        'O resultado não foi salvo porque o cofre privado continua bloqueado.',
      'fr' =>
        'Le résultat n’a pas été enregistré, car le coffre privé est resté verrouillé.',
      'es' =>
        'El resultado no se guardó porque la bóveda privada siguió bloqueada.',
      'ar' => 'لم تُحفَظ النتيجة لأن الخزنة الخاصة بقيت مقفلة.',
      'hi' => 'परिणाम सेव नहीं हुआ क्योंकि निजी वॉल्ट लॉक रहा।',
      'zh' => '结果未保存，因为私密保险库仍处于锁定状态。',
      _ => 'Result not saved because the private vault stayed locked.',
    };
  }

  String get storageUnavailable {
    return switch (languageCode) {
      'pt' =>
        'O histórico privado foi desativado porque este aparelho não oferece proteção de tela adequada.',
      'fr' =>
        'L’historique privé est désactivé, car cet appareil n’offre pas de protection d’écran suffisante.',
      'es' =>
        'El historial privado se desactivó porque este dispositivo no ofrece una protección de pantalla adecuada.',
      'ar' =>
        'تم تعطيل حفظ السجل الخاص لأن هذا الجهاز لا يوفّر حماية شاشة مناسبة.',
      'hi' =>
        'निजी हिस्ट्री सेव नहीं की गई क्योंकि इस डिवाइस पर पर्याप्त स्क्रीन सुरक्षा उपलब्ध नहीं है।',
      'zh' => '私密历史记录已停用，因为此设备没有足够的屏幕保护。',
      _ =>
        'Private history was disabled because this device does not offer a strong enough screen lock.',
    };
  }

  String get storageFailed {
    return switch (languageCode) {
      'pt' => 'Não foi possível salvar este resultado privado agora.',
      'fr' => 'Impossible d’enregistrer ce résultat privé pour le moment.',
      'es' => 'No fue posible guardar este resultado privado en este momento.',
      'ar' => 'تعذّر حفظ هذه النتيجة الخاصة الآن.',
      'hi' => 'यह निजी परिणाम अभी सेव नहीं हो सका।',
      'zh' => '当前无法保存这份私密结果。',
      _ => 'This private result could not be saved right now.',
    };
  }

  String get personalLiabilityQuestion {
    return switch (languageCode) {
      'pt' =>
        'Se eu assinar, isso me torna pessoalmente responsável ou fiador de outra pessoa?',
      'fr' =>
        'Si je signe, est-ce que je deviens personnellement responsable ou caution pour quelqu’un d’autre ?',
      'es' =>
        'Si firmo, ¿esto me vuelve responsable personalmente o avalista de otra persona?',
      'ar' => 'إذا وقّعت، هل أصبح مسؤولًا شخصيًا أو ضامنًا عن شخص آخر؟',
      'hi' =>
        'अगर मैं साइन करूँ, तो क्या मैं व्यक्तिगत रूप से जिम्मेदार या किसी और का गारंटर बन जाऊँगा?',
      'zh' => '如果我签字，我是否会变成个人责任人或他人的担保人？',
      _ =>
        'If I sign, do I become personally liable or a guarantor for someone else?',
    };
  }

  String get termsChangeQuestion {
    return switch (languageCode) {
      'pt' =>
        'Você pode preencher todos os espaços em branco e me entregar a versão final limpa antes de eu assinar?',
      'fr' =>
        'Pouvez-vous remplir tous les champs vides et me remettre la version finale propre avant que je signe ?',
      'es' =>
        '¿Puedes completar todos los espacios en blanco y entregarme la versión final limpia antes de que firme?',
      'ar' =>
        'هل يمكن ملء كل الفراغات وتسليمي النسخة النهائية النظيفة قبل التوقيع؟',
      'hi' =>
        'क्या आप सभी खाली जगहें भरकर मुझे साइन से पहले अंतिम साफ़ कॉपी दे सकते हैं?',
      'zh' => '你们能否先补全所有空白，并在我签字前给我最终清晰版本？',
      _ =>
        'Can you fill every blank and give me the final clean copy before I sign?',
    };
  }

  String get assetExposureQuestion {
    return switch (languageCode) {
      'pt' =>
        'Quais valores, salários ou bens meus podem ser cobrados se houver atraso ou disputa?',
      'fr' =>
        'Quels montants, salaires ou biens peuvent être réclamés contre moi en cas de retard ou de litige ?',
      'es' =>
        '¿Qué dinero, salario o bienes míos pueden reclamar si hay atraso o disputa?',
      'ar' =>
        'ما الأموال أو الراتب أو الأصول التي يمكن الرجوع بها عليّ إذا حدث تأخير أو نزاع؟',
      'hi' =>
        'अगर देरी या विवाद हुआ, तो मेरे कौन से पैसे, वेतन या संपत्ति पर दावा किया जा सकता है?',
      'zh' => '如果发生逾期或争议，他们可以向我的哪些资金、工资或财产追索？',
      _ =>
        'What money, salary, or assets can be claimed from me if there is a delay or dispute?',
    };
  }

  String get defaultSaferNextStep {
    return switch (languageCode) {
      'pt' =>
        'Peça uma cópia limpa, leve tempo para revisar e não assine enquanto a responsabilidade ainda estiver ambígua.',
      'fr' =>
        'Demandez une copie propre, prenez le temps de relire et ne signez pas tant que la responsabilité reste ambiguë.',
      'es' =>
        'Pide una copia limpia, tómate tiempo para revisarla y no firmes mientras la responsabilidad siga ambigua.',
      'ar' =>
        'اطلب نسخة نظيفة، وخذ وقتك في المراجعة، ولا توقّع ما دامت المسؤولية ما زالت غامضة.',
      'hi' =>
        'एक साफ़ कॉपी माँगें, समीक्षा के लिए समय लें, और जब तक जिम्मेदारी साफ़ न हो तब तक साइन न करें।',
      'zh' => '先索要清晰版本，留出复核时间，在责任仍不清楚时不要签字。',
      _ =>
        'Ask for a clean copy, take time to review it, and do not sign while the liability is still ambiguous.',
    };
  }

  String actionPlanTitle({required bool usesGemma}) {
    if (usesGemma) {
      return switch (languageCode) {
        'pt' => 'Plano de ação do Gemma',
        'fr' => 'Plan d’action Gemma',
        'es' => 'Plan de acción de Gemma',
        'ar' => 'خطة التحرك من Gemma',
        'hi' => 'Gemma कार्य योजना',
        'zh' => 'Gemma 行动计划',
        _ => 'Gemma action plan',
      };
    }

    return switch (languageCode) {
      'pt' => 'Próximas ações recomendadas',
      'fr' => 'Prochaines actions recommandées',
      'es' => 'Próximas acciones recomendadas',
      'ar' => 'الخطوات المقترحة الآن',
      'hi' => 'अगले सुझाए गए कदम',
      'zh' => '建议的下一步',
      _ => 'Recommended next actions',
    };
  }

  String get trustLayerTitle {
    return switch (languageCode) {
      'pt' => 'Camada de confiança',
      'fr' => 'Couche de confiance',
      'es' => 'Capa de confianza',
      'ar' => 'طبقة الثقة',
      'hi' => 'विश्वास परत',
      'zh' => '可信层',
      _ => 'Trust layer',
    };
  }

  String trustLayerSummary(String level) {
    return switch (level) {
      'grounded' => switch (languageCode) {
          'pt' =>
            'A maior parte dos alertas está ancorada diretamente no texto do documento.',
          'fr' =>
            'La plupart des alertes sont directement ancrées dans le texte du document.',
          'es' =>
            'La mayoría de las alertas están ancladas directamente en el texto del documento.',
          'ar' => 'معظم التحذيرات مثبتة مباشرة في نص المستند.',
          'hi' => 'अधिकांश चेतावनियाँ सीधे दस्तावेज़ के पाठ से जुड़ी हुई हैं।',
          'zh' => '大多数警告都直接锚定在文档文本中。',
          _ => 'Most warnings are tied directly to the document text.',
        },
      'mixed' => switch (languageCode) {
          'pt' =>
            'Parte dos alertas está ancorada no texto, mas pelo menos um ponto ainda precisa de revisão manual.',
          'fr' =>
            'Une partie des alertes est ancrée dans le texte, mais au moins un point demande encore une vérification manuelle.',
          'es' =>
            'Parte de las alertas está anclada en el texto, pero al menos un punto todavía requiere revisión manual.',
          'ar' =>
            'بعض التحذيرات مثبتة في النص، لكن يوجد بند واحد على الأقل ما زال يحتاج مراجعة يدوية.',
          'hi' =>
            'कुछ चेतावनियाँ पाठ से जुड़ी हैं, लेकिन कम से कम एक बिंदु अभी भी मैनुअल समीक्षा चाहता है।',
          'zh' => '部分警告已锚定到文本，但至少还有一项需要人工复核。',
          _ =>
            'Some warnings are grounded, but at least one point still needs manual review.',
        },
      _ => switch (languageCode) {
          'pt' =>
            'Use isto como sinal de cautela e revise o documento novamente antes de agir.',
          'fr' =>
            'Considérez ceci comme un signal de prudence et relisez le document avant d’agir.',
          'es' =>
            'Toma esto como una señal de cautela y revisa el documento otra vez antes de actuar.',
          'ar' =>
            'تعامل مع النتيجة كإشارة حذر، وراجع المستند مرة أخرى قبل أي خطوة.',
          'hi' =>
            'इसे सावधानी संकेत की तरह लें और कोई कदम उठाने से पहले दस्तावेज़ फिर से जाँचें।',
          'zh' => '请把这当作谨慎信号，在行动前再次复核文档。',
          _ =>
            'Treat this as a caution signal and review the document again before acting.',
        },
    };
  }

  String translateTrustLevel(String level) {
    return switch (level) {
      'grounded' => switch (languageCode) {
          'pt' => 'Ancorado',
          'fr' => 'Ancré',
          'es' => 'Anclado',
          'ar' => 'مثبت',
          'hi' => 'प्रमाणित',
          'zh' => '已锚定',
          _ => 'Grounded',
        },
      'contextual' => switch (languageCode) {
          'pt' => 'Do contexto',
          'fr' => 'Du contexte',
          'es' => 'Desde el contexto',
          'ar' => 'من السياق',
          'hi' => 'संदर्भ से',
          'zh' => '来自上下文',
          _ => 'Context-based',
        },
      'inferred' => switch (languageCode) {
          'pt' => 'Inferido',
          'fr' => 'Inféré',
          'es' => 'Inferido',
          'ar' => 'مستنتج',
          'hi' => 'अनुमान',
          'zh' => '推断',
          _ => 'Inferred',
        },
      _ => switch (languageCode) {
          'pt' => 'Revisar',
          'fr' => 'À vérifier',
          'es' => 'Revisar',
          'ar' => 'يحتاج مراجعة',
          'hi' => 'समीक्षा करें',
          'zh' => '待复核',
          _ => 'Needs review',
        },
    };
  }

  String actionLabel(String actionId) {
    return switch (actionId) {
      'open_legal_help' => switch (languageCode) {
          'pt' => 'Abrir ajuda legal',
          'fr' => 'Ouvrir l’aide juridique',
          'es' => 'Abrir ayuda legal',
          'ar' => 'افتح المساعدة القانونية',
          'hi' => 'कानूनी सहायता खोलें',
          'zh' => '打开法律帮助',
          _ => 'Open legal help',
        },
      'copy_questions' => switch (languageCode) {
          'pt' => 'Copiar perguntas',
          'fr' => 'Copier les questions',
          'es' => 'Copiar preguntas',
          'ar' => 'انسخ الأسئلة',
          'hi' => 'सवाल कॉपी करें',
          'zh' => '复制问题',
          _ => 'Copy questions',
        },
      'set_up_gemma' => switch (languageCode) {
          'pt' => 'Configurar Gemma 4',
          'fr' => 'Configurer Gemma 4',
          'es' => 'Configurar Gemma 4',
          'ar' => 'جهّز Gemma 4',
          'hi' => 'Gemma 4 सेट करें',
          'zh' => '设置 Gemma 4',
          _ => 'Set up Gemma 4',
        },
      _ => switch (languageCode) {
          'pt' => 'Revisar o documento',
          'fr' => 'Revoir le document',
          'es' => 'Revisar el documento',
          'ar' => 'راجع المستند',
          'hi' => 'दस्तावेज़ फिर देखें',
          'zh' => '重新检查文档',
          _ => 'Review the document again',
        },
    };
  }

  String get openLegalHelpActionReason {
    return switch (languageCode) {
      'pt' =>
        'A exposição parece alta o bastante para justificar ajuda local real antes de assinar.',
      'fr' =>
        'Le niveau de risque semble assez élevé pour justifier une aide locale réelle avant toute signature.',
      'es' =>
        'La exposición parece lo bastante alta como para justificar ayuda local real antes de firmar.',
      'ar' =>
        'مستوى الخطر يبدو مرتفعًا بما يكفي لطلب مساعدة قانونية حقيقية قبل التوقيع.',
      'hi' =>
        'जोखिम इतना ऊँचा दिख रहा है कि साइन करने से पहले स्थानीय कानूनी मदद लेना उचित है।',
      'zh' => '风险看起来足够高，签字前值得先寻求本地法律帮助。',
      _ =>
        'The exposure looks high enough to justify real local legal help before signing.',
    };
  }

  String get copyQuestionsActionReason {
    return switch (languageCode) {
      'pt' =>
        'Leve perguntas claras para a outra parte antes de concordar com qualquer responsabilidade.',
      'fr' =>
        'Apportez des questions claires à l’autre partie avant d’accepter toute responsabilité.',
      'es' =>
        'Lleva preguntas claras a la otra parte antes de aceptar cualquier responsabilidad.',
      'ar' => 'خذ معك أسئلة واضحة للطرف الآخر قبل قبول أي مسؤولية.',
      'hi' => 'कोई भी जिम्मेदारी मानने से पहले सामने वाले से साफ़ सवाल पूछें।',
      'zh' => '在接受任何责任之前，先带着明确问题去追问对方。',
      _ =>
        'Bring clear questions back to the other side before accepting any liability.',
    };
  }

  String get reviewDocumentAgainActionReason {
    return switch (languageCode) {
      'pt' =>
        'Revise o texto outra vez para preencher lacunas e confirmar que o OCR capturou o que realmente importa.',
      'fr' =>
        'Revérifiez le texte pour combler les manques et confirmer que l’OCR a bien capturé l’essentiel.',
      'es' =>
        'Revisa el texto otra vez para llenar huecos y confirmar que el OCR captó lo importante.',
      'ar' =>
        'راجع النص مرة أخرى لملء أي نقص والتأكد أن الاستخراج التقط ما يهم فعلًا.',
      'hi' =>
        'पाठ फिर से जाँचें ताकि खाली हिस्से भर सकें और यह पक्का हो कि OCR ने जरूरी बात पकड़ी है।',
      'zh' => '再次检查文本，补足缺失部分，并确认 OCR 抓到了真正重要的内容。',
      _ =>
        'Review the text again to fill any gaps and confirm OCR captured what matters.',
    };
  }

  String get setUpGemmaActionReason {
    return switch (languageCode) {
      'pt' =>
        'Instale o modelo para trocar a verificação limitada pela análise completa no dispositivo.',
      'fr' =>
        'Installez le modèle pour remplacer la vérification limitée par l’analyse complète sur l’appareil.',
      'es' =>
        'Instala el modelo para cambiar el escaneo limitado por el análisis completo en el dispositivo.',
      'ar' => 'ثبّت الموديل لتحويل الفحص المحدود إلى تحليل كامل على الجهاز.',
      'hi' =>
        'सीमित स्कैन की जगह पूरा ऑन-डिवाइस विश्लेषण पाने के लिए मॉडल इंस्टॉल करें।',
      'zh' => '安装模型，把有限扫描升级为完整的端侧分析。',
      _ =>
        'Install the model to replace the limited scan with full on-device analysis.',
    };
  }

  String get copiedQuestionsMessage {
    return switch (languageCode) {
      'pt' => 'As perguntas e o próximo passo mais seguro foram copiados.',
      'fr' => 'Les questions et l’étape la plus sûre ont été copiées.',
      'es' => 'Se copiaron las preguntas y el paso más seguro.',
      'ar' => 'تم نسخ الأسئلة والخطوة الأكثر أمانًا.',
      'hi' => 'सवाल और सबसे सुरक्षित अगला कदम कॉपी हो गया है।',
      'zh' => '问题列表和更稳妥的下一步已复制。',
      _ => 'Questions and the safer next step were copied.',
    };
  }

  String _t(String key) {
    return _strings[languageCode]?[key] ?? _strings['en']![key]!;
  }
}

extension AppCopyLocaleTag on BuildContext {
  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}
