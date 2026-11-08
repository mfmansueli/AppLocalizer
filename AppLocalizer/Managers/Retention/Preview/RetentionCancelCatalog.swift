//
//  RetentionCancelCatalog.swift
//  AppLocalizer
//

import Foundation

/// Apple's Confirm Cancellation words in the 18 languages Retention
/// starts with, by locale code or language. The preview's approximation of
/// what the system shows; a language that isn't here reads English.
enum RetentionCancelCatalog {
    static let table: [String: RetentionCancelStrings] = [
        "en": .english,
        "de": RetentionCancelStrings(
            title: "Kündigung bestätigen", end: "Wenn du dieses Abo kündigst, endet der Dienst am {date}.", from: "VOM ENTWICKLER",
            cancel: "Abo kündigen", keep: "Abo behalten", accept: "Angebot annehmen", oneMonth: "1 Monat", months: "{n} Monate",
            perMonth: "/Monat", perYear: "/Jahr", discount: "{dur} {pct} % günstiger, dann {price}{per}",
            free: "{dur} gratis, dann {price}{per}", upFront: "{dur} für {offer}, dann {price}{per}"
        ),
        "fr": RetentionCancelStrings(
            title: "Confirmer la résiliation", end: "Si vous résiliez cet abonnement, le service prendra fin le {date}.",
            from: "DU DÉVELOPPEUR", cancel: "Résilier l’abonnement", keep: "Conserver l’abonnement", accept: "Accepter l’offre",
            oneMonth: "1 mois", months: "{n} mois", perMonth: "/mois", perYear: "/an", discount: "{dur} à −{pct} %, puis {price}{per}",
            free: "{dur} offert, puis {price}{per}", upFront: "{dur} pour {offer}, puis {price}{per}"
        ),
        "ja": RetentionCancelStrings(
            title: "解約の確認", end: "このサブスクリプションを解約すると、サービスは{date}に終了します。", from: "デベロッパより",
            cancel: "サブスクリプションを解約", keep: "サブスクリプションを継続", accept: "オファーを受ける", oneMonth: "1か月", months: "{n}か月",
            perMonth: "（月額）", perYear: "（年額）", discount: "{dur}{pct}%オフ、その後は{price}{per}",
            free: "{dur}無料、その後は{price}{per}", upFront: "{dur}{offer}、その後は{price}{per}"
        ),
        "ar": RetentionCancelStrings(
            title: "تأكيد الإلغاء", end: "إذا ألغيت هذا الاشتراك، تنتهي الخدمة في {date}.", from: "من المطوّر",
            cancel: "إلغاء الاشتراك", keep: "الإبقاء على الاشتراك", accept: "قبول العرض", oneMonth: "شهر واحد", months: "{n} أشهر",
            perMonth: " شهريًا", perYear: " سنويًا", discount: "{dur} بخصم {pct}٪، ثم {price}{per}",
            free: "{dur} مجانًا، ثم {price}{per}", upFront: "{dur} مقابل {offer}، ثم {price}{per}"
        ),
        "es": RetentionCancelStrings(
            title: "Confirmar cancelación", end: "Si cancelas esta suscripción, el servicio terminará el {date}.",
            from: "DEL DESARROLLADOR", cancel: "Cancelar suscripción", keep: "Mantener suscripción", accept: "Aceptar oferta"
        ),
        "it": RetentionCancelStrings(
            title: "Conferma annullamento", end: "Se annulli questo abbonamento, il servizio terminerà il {date}.",
            from: "DALLO SVILUPPATORE", cancel: "Annulla abbonamento", keep: "Mantieni abbonamento", accept: "Accetta offerta"
        ),
        "pt": RetentionCancelStrings(
            title: "Confirmar cancelamento", end: "Se você cancelar esta assinatura, o serviço terminará em {date}.",
            from: "DO DESENVOLVEDOR", cancel: "Cancelar assinatura", keep: "Manter assinatura", accept: "Aceitar oferta"
        ),
        "nl": RetentionCancelStrings(
            title: "Opzegging bevestigen", end: "Als je dit abonnement opzegt, eindigt de dienst op {date}.",
            from: "VAN DE ONTWIKKELAAR", cancel: "Abonnement opzeggen", keep: "Abonnement behouden", accept: "Aanbod accepteren"
        ),
        "sv": RetentionCancelStrings(
            title: "Bekräfta avslut", end: "Om du avslutar prenumerationen upphör tjänsten den {date}.",
            from: "FRÅN UTVECKLAREN", cancel: "Avsluta prenumeration", keep: "Behåll prenumeration", accept: "Acceptera erbjudandet"
        ),
        "ko": RetentionCancelStrings(
            title: "취소 확인", end: "이 구독을 취소하면 서비스가 {date}에 종료됩니다.",
            from: "개발자 메시지", cancel: "구독 취소", keep: "구독 유지", accept: "혜택 받기"
        ),
        "zh-Hans": RetentionCancelStrings(
            title: "确认取消", end: "如果取消此订阅，服务将于{date}结束。", from: "来自开发者", cancel: "取消订阅", keep: "保留订阅", accept: "接受优惠"
        ),
        "zh-Hant": RetentionCancelStrings(
            title: "確認取消", end: "如果取消此訂閱，服務將於{date}結束。", from: "來自開發者", cancel: "取消訂閱", keep: "保留訂閱", accept: "接受優惠"
        ),
        "ru": RetentionCancelStrings(
            title: "Подтвердите отмену", end: "Если вы отмените подписку, услуга закончится {date}.",
            from: "ОТ РАЗРАБОТЧИКА", cancel: "Отменить подписку", keep: "Сохранить подписку", accept: "Принять предложение"
        ),
        "tr": RetentionCancelStrings(
            title: "İptali Onayla", end: "Bu aboneliği iptal edersen hizmet {date} tarihinde sona erer.",
            from: "GELİŞTİRİCİDEN", cancel: "Aboneliği İptal Et", keep: "Aboneliği Koru", accept: "Teklifi Kabul Et"
        ),
        "pl": RetentionCancelStrings(
            title: "Potwierdź anulowanie", end: "Jeśli anulujesz tę subskrypcję, usługa zakończy się {date}.",
            from: "OD DEWELOPERA", cancel: "Anuluj subskrypcję", keep: "Zachowaj subskrypcję", accept: "Przyjmij ofertę"
        ),
        "he": RetentionCancelStrings(
            title: "אישור ביטול", end: "אם תבטלו את המינוי, השירות יסתיים ב-{date}.",
            from: "מהמפתח", cancel: "ביטול המינוי", keep: "שמירת המינוי", accept: "קבלת ההצעה"
        ),
        "hi": RetentionCancelStrings(
            title: "रद्द करने की पुष्टि करें", end: "यदि आप यह सदस्यता रद्द करते हैं, तो आपकी सेवा {date} को समाप्त हो जाएगी।",
            from: "डेवलपर की ओर से", cancel: "सदस्यता रद्द करें", keep: "सदस्यता जारी रखें", accept: "ऑफ़र स्वीकार करें"
        ),
    ]
}
