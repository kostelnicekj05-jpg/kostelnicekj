# Moje centrum pro iPhone

Pilot v češtině pro iOS 17+. Navigace Dnes, Zápis O2 a Sport.

## Spuštění na Macu

1. Rozbal ZIP a otevři MojeCentrum.xcodeproj v Xcode.
2. Zvol cíl MojeCentrum → Signing & Capabilities → Team a vyber svůj Apple účet.
3. Připoj iPhone, vyber ho v horní liště Xcode a spusť Run. Povol režim vývojáře, pokud tě iPhone vyzve.
4. Na kartě Dnes povol Kalendář a Připomínky. Ověř dnešní událost a nedokončenou připomínku.
5. Pro akční tlačítko lze v Apple Zkratkách vytvořit zkratku s akcí Otevřít aplikaci → Moje centrum. Pro přechod přímo na přehled lze použít URL mojecentrum://dnes nebo vyzkoušet akci Otevřít přehled dne.

Zápis O2 použije diktování české klávesnice. Tlačítko zkopíruje anonymizovaný text se zadáním pro ChatGPT. V chatu ho vložíš ručně. Plány Sigmy a osobního sportu lze upravit a ukládají se lokálně.

Projekt vyžaduje první sestavení a test v Xcode. Ranní automatizace, automatické zpracování AI, CRM integrace, tréninkový deník a Apple Zdraví v tomto projektu zatím nejsou. Pro TestFlight je potřeba podepsat sestavení a zaregistrovat aplikaci v App Store Connect.

## Windows + iPhone přes Codemagic

1. Na Windows rozbal ZIP. Vytvoř soukromý repozitář GitHub a nahraj obsah složky MojeCentrum. Soubor codemagic.yaml a složka MojeCentrum.xcodeproj musí být přímo v kořeni repozitáře.
2. V Codemagic připoj repozitář a spusť workflow „iOS – kontrola sestavení“. Jde o sestavení pro simulátor bez podpisu. Sestavení se zatím na iPhone nenainstaluje.
3. Pro instalaci se přihlas do Apple Developer Program. Zaregistruj Bundle ID cz.kostelnicek.mojecentrum a založ stejnojmenný záznam aplikace s tímto ID v App Store Connect. Pokud je Bundle ID už obsazené, změň ho v project.pbxproj i codemagic.yaml.
4. Propoj Codemagic s App Store Connect. Integraci pojmenuj MojeCentrum přesně podle YAML. V nastavení podepisování v Codemagic nastav distribuční certifikát a App Store provisioning profil pro tento Bundle ID. Pokyny: https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/
5. Spusť workflow „iOS – TestFlight“. Po zpracování sestavení v App Store Connect případně vyplň informace o šifrování. V TestFlight vytvoř interní skupinu, přidej do ní své Apple ID a připoj sestavení. Na iPhonu otevři pozvánku v TestFlight.

Konfigurace a soubory projektu prošly statickou kontrolou. Oba workflow ještě musí poprvé proběhnout na vzdáleném Macu.
