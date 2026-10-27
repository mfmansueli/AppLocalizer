//
//  StorePageSampleData+Import.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension StorePageSampleData {
    static let translatorFileName = "Lumen-1.4-translations.xliff"

    /// A translator’s XLIFF, as in the import screenshot: five changes in
    /// five locales, plus “pt” (ambiguous, 9 fields) and a French subtitle
    /// over the limit (33/30). Unchanged units (French and German names) don’t
    /// show up as changes.
    static let translatorXLIFF = """
    <?xml version="1.0" encoding="UTF-8"?>
    <xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" version="1.2">
      <file original="Lumen Journal 1.4" source-language="en-US" target-language="fr-FR" \
    datatype="plaintext">
        <body>
          <trans-unit id="name" xml:space="preserve">
            <source>Lumen: Daily Journal</source>
            <target state="translated">Lumen : Journal intime</target>
          </trans-unit>
          <trans-unit id="subtitle" xml:space="preserve">
            <source>Private notes, gentle prompts</source>
            <target state="translated">Notes privées et questions douces</target>
          </trans-unit>
          <trans-unit id="promotionalText" xml:space="preserve">
            <source>New: weekly reflections gather your best moments into one calm page.</source>
            <target state="translated">Nouveau : les bilans de la semaine réunissent vos plus beaux \
    moments sur une page apaisée.</target>
          </trans-unit>
        </body>
      </file>
      <file original="Lumen Journal 1.4" source-language="en-US" target-language="de-DE" \
    datatype="plaintext">
        <body>
          <trans-unit id="name" xml:space="preserve">
            <source>Lumen: Daily Journal</source>
            <target state="translated">Lumen: Tagebuch</target>
          </trans-unit>
          <trans-unit id="whatsNew" xml:space="preserve">
            <source>• Weekly reflections: a calm summary of your week
    • Faster search across years of entries
    • Fixes iCloud sync on older devices</source>
            <target state="translated">• Wochenrückblicke: eine ruhige Zusammenfassung deiner Woche
    • Schnellere Suche über Jahre an Einträgen
    • Behebt die iCloud-Synchronisierung auf älteren Geräten</target>
          </trans-unit>
        </body>
      </file>
      <file original="Lumen Journal 1.4" source-language="en-US" target-language="es-MX" \
    datatype="plaintext">
        <body>
          <trans-unit id="description" xml:space="preserve">
            <source>Lumen is a quiet place to write every day. Answer a gentle prompt or start from a \
    blank page, add a photo, and Lumen keeps it private on your devices.

    • Daily prompts that adapt to your mood
    • Weekly reflections that gather your highlights
    • Search years of entries in an instant
    • Locked with Face ID, synced with iCloud

    Lumen Plus unlocks unlimited photos, themes and PDF export.</source>
            <target state="translated">Lumen es un lugar tranquilo para escribir cada día. Responde a \
    una pregunta amable o empieza en blanco, añade una foto y Lumen lo guarda todo en privado en tus \
    dispositivos.

    • Preguntas diarias que se adaptan a tu estado de ánimo
    • Resúmenes semanales con tus mejores momentos
    • Busca años de entradas al instante
    • Protegido con Face ID, sincronizado con iCloud

    Lumen Plus desbloquea fotos ilimitadas, temas y exportación a PDF.</target>
          </trans-unit>
        </body>
      </file>
      <file original="Lumen Journal 1.4" source-language="en-US" target-language="ja" \
    datatype="plaintext">
        <body>
          <trans-unit id="keywords" xml:space="preserve">
            <source>diary,mood,gratitude,reflection,writing,mindful,habit,memories,self \
    care,planner,journal</source>
            <target state="translated">日記,ジャーナル,気分,感謝,振り返り,習慣,メモ,マインドフル,思い出,手帳</target>
          </trans-unit>
        </body>
      </file>
      <file original="Lumen Journal 1.4" source-language="en-US" target-language="it" \
    datatype="plaintext">
        <body>
          <trans-unit id="promotionalText" xml:space="preserve">
            <source>New: weekly reflections gather your best moments into one calm page.</source>
            <target state="translated">Novità: le riflessioni settimanali raccolgono i tuoi momenti \
    migliori in una pagina serena.</target>
          </trans-unit>
        </body>
      </file>
      <file original="Lumen Journal 1.4" source-language="en-US" target-language="pt" \
    datatype="plaintext">
        <body>
          <trans-unit id="name" xml:space="preserve">
            <source>Lumen: Daily Journal</source>
            <target state="translated">Lumen: Diário</target>
          </trans-unit>
          <trans-unit id="subtitle" xml:space="preserve">
            <source>Private notes, gentle prompts</source>
            <target state="translated">Diário privado, dicas gentis</target>
          </trans-unit>
          <trans-unit id="privacyPolicyUrl" xml:space="preserve">
            <source>https://lumen.example/privacy</source>
            <target state="translated">https://lumen.example/privacy</target>
          </trans-unit>
          <trans-unit id="promotionalText" xml:space="preserve">
            <source>New: weekly reflections gather your best moments into one calm page.</source>
            <target state="translated">Novo: reflexões semanais reúnem seus melhores momentos em uma \
    página tranquila.</target>
          </trans-unit>
          <trans-unit id="description" xml:space="preserve">
            <source>Lumen is a quiet place to write every day. Answer a gentle prompt or start from a \
    blank page, add a photo, and Lumen keeps it private on your devices.

    • Daily prompts that adapt to your mood
    • Weekly reflections that gather your highlights
    • Search years of entries in an instant
    • Locked with Face ID, synced with iCloud

    Lumen Plus unlocks unlimited photos, themes and PDF export.</source>
            <target state="translated">O Lumen é um lugar tranquilo para escrever todos os dias. \
    Responda a uma pergunta gentil ou comece do zero, adicione uma foto e deixe tudo guardado só nos \
    seus aparelhos.

    • Perguntas diárias que se adaptam ao seu humor
    • Reflexões semanais com os seus destaques
    • Busque anos de anotações num instante
    • Protegido com Face ID, sincronizado pelo iCloud

    O Lumen Plus libera fotos ilimitadas, temas e exportação em PDF.</target>
          </trans-unit>
          <trans-unit id="keywords" xml:space="preserve">
            <source>diary,mood,gratitude,reflection,writing,mindful,habit,memories,self \
    care,planner,journal</source>
            <target state="translated">diario,humor,gratidao,reflexao,escrita,habito,memorias,autocuidad\
    o,anotacoes,agenda</target>
          </trans-unit>
          <trans-unit id="whatsNew" xml:space="preserve">
            <source>• Weekly reflections: a calm summary of your week
    • Faster search across years of entries
    • Fixes iCloud sync on older devices</source>
            <target state="translated">• Reflexões semanais: um resumo tranquilo da sua semana
    • Busca mais rápida em anos de anotações
    • Corrige a sincronização do iCloud em aparelhos mais antigos</target>
          </trans-unit>
          <trans-unit id="supportUrl" xml:space="preserve">
            <source>https://lumen.example/support</source>
            <target state="translated">https://lumen.example/support</target>
          </trans-unit>
          <trans-unit id="marketingUrl" xml:space="preserve">
            <source>https://lumen.example</source>
            <target state="translated">https://lumen.example</target>
          </trans-unit>
        </body>
      </file>
    </xliff>

    """
}
#endif
