# Lumina-OS Team Execution Plan

## الهدف
هذه الخطة تقسم الشغل بين `عبدالله` و`محمد` حتى:
- لا يشتغل الاثنان على نفس الملفات بدون قصد
- لا يحدث تكرار أو تضارب أو merge conflicts غير ضرورية
- يبقى كل PR واضح ومرتبط بمالك واحد

## قواعد العمل المشتركة
- كل مهمة كبيرة لازم تبدأ من GitHub Issue أو اتفاق واضح داخل المحادثة.
- كل مهمة لها `Owner` واحد فقط.
- كل Owner يعمل على branch خاص به.
- لا يوجد push مباشر إلى `main`.
- كل تغيير مهم يمر عبر Pull Request.
- الشخص الثاني يراجع PR قبل الدمج.
- إذا احتاجت المهمة لمسارات تخص الشخص الثاني، يتوقف صاحب المهمة ويطلب تنسيقًا أولًا.

## قاعدة الفروع
- عبدالله يستخدم فروعًا مثل:
  - `abdallah/build-stable-01`
  - `abdallah/vm-cycle-stable-01`
  - `abdallah/release-prep-01`
- محمد يستخدم فروعًا مثل:
  - `mohammad/welcome-polish-01`
  - `mohammad/update-center-ui-01`
  - `mohammad/sddm-polish-01`

## الملفات المشتركة الحساسة
هذه الملفات لا يعدلها أي شخص بشكل عشوائي:
- `README.md`
- `CHANGELOG.md`
- `status/CURRENT-STATUS.md`
- `status/PROJECT-SUMMARY.md`
- `.github/`
- `archiso-profile/airootfs/etc/ahmados-release.conf`
- أي rename عميق للمعرفات الداخلية مثل `ahmados-*` أو `com.ahmados.*`

إذا احتاج أحد هذه الملفات:
- يذكر ذلك داخل الـ PR
- ويحاول أن يكون التعديل في آخر خطوة بعد الاتفاق

## خطة عبدالله

### الملكية الأساسية
عبدالله يملك حاليًا مسار:
- البناء
- الإقلاع
- الاختبار
- الأدلة والتقارير
- الجاهزية والإصدار

### الملفات التي يملكها
- `archiso-profile/profiledef.sh`
- `archiso-profile/packages.x86_64`
- `archiso-profile/build-variants/`
- `archiso-profile/grub/`
- `archiso-profile/syslinux/`
- `archiso-profile/efiboot/`
- `scripts/build-iso-arch.sh`
- `scripts/build-iso.ps1`
- `scripts/bootstrap-arch-build-env.sh`
- `scripts/validate-profile.ps1`
- `scripts/validate-profile.sh`
- `scripts/write-build-manifest.sh`
- `scripts/start-vm-test-cycle.ps1`
- `scripts/finish-vm-test-cycle.ps1`
- `scripts/new-vm-test-report.ps1`
- `scripts/new-test-session.ps1`
- `scripts/audit-test-session.ps1`
- `scripts/sync-test-blockers.ps1`
- `scripts/sync-readiness-status.ps1`
- `scripts/sync-validation-matrix.ps1`
- `scripts/import-diagnostics-bundle.ps1`
- `status/builds/`
- `status/vm-tests/`
- `status/test-sessions/`
- `status/test-session-audits/`
- `status/diagnostics/`
- `status/blockers/`
- `status/readiness/`
- `status/validation-matrix/`

### المطلوب من عبدالله الآن
1. تنفيذ أول build حقيقي داخل Arch لوضع `stable`.
2. تنفيذ أول VM cycle حقيقي لوضع `stable`.
3. تنفيذ أول build حقيقي داخل Arch لوضع `login-test`.
4. تنفيذ أول VM cycle حقيقي لوضع `login-test`.
5. تحديث حالة الجاهزية بعد الأدلة الحقيقية.
6. تجهيز أول release package بعد نجاح البناء والاختبار.

### يعتبر شغله منجزًا عندما
- يوجد build manifest حقيقي
- يوجد VM report حقيقي
- توجد diagnostics import حقيقية
- readiness وvalidation matrix مبنيتان على تشغيل فعلي

## خطة محمد

### الملكية الأساسية
محمد يملك حاليًا مسار:
- واجهات النظام
- التنعيم البصري
- تجربة الاستخدام
- تحسين النصوص والواجهات

### الملفات التي يملكها
- `archiso-profile/airootfs/usr/share/ahmados/welcome/`
- `archiso-profile/airootfs/usr/share/ahmados/update-center/`
- `archiso-profile/airootfs/usr/share/sddm/themes/ahmados/`
- `archiso-profile/airootfs/usr/share/color-schemes/`
- `archiso-profile/airootfs/usr/share/ahmados/wallpapers/`
- `branding/`
- `docs/DESIGN-BRIEF.md`
- `docs/DESKTOP-LAYOUT-SPEC.md`
- `docs/SDDM-THEME-SPEC.md`
- `docs/WELCOME-APP-SPEC.md`
- `docs/WELCOME-IMPLEMENTATION.md`
- `docs/UPDATE-CENTER-SPEC.md`
- `docs/UPDATE-CENTER-IMPLEMENTATION.md`
- `docs/SETTINGS-SHELL-SPEC.md`
- `docs/SYSTEM-THEME-IMPLEMENTATION.md`
- `docs/UX-AGENT-REPORT.md`

### المطلوب من محمد الآن
1. تحسين Welcome بصريًا ونصيًا بدون كسر المنطق الحالي.
2. تحسين Update Center من ناحية النصوص والحالات مثل:
   - loading
   - empty
   - error
   - channel wording
3. تحسين SDDM theme بصريًا وتوحيد الاسم `Lumina-OS`.
4. تنظيف أسماء الخلفيات والألوان وعرضها للمستخدم بشكل أوضح.
5. إبقاء ملفات UX/specs متوافقة مع التنفيذ الحالي.

### ما لا يفعله محمد حاليًا
- لا يعدل bootloader files
- لا يعدل build scripts
- لا يعدل validators
- لا يغير flow الخاص بالأدلة والتقارير
- لا يعمل rename عميق للمعرفات الداخلية

### يعتبر شغله منجزًا عندما
- Welcome وUpdate Center وSDDM صارت أوضح وأجمل
- النصوص كلها متسقة مع `Lumina-OS`
- لا يوجد تعارض مع build/test workflow

## ترتيب العمل الحالي
1. عبدالله يركز على build/test path الحقيقي.
2. محمد يركز على polish داخل الواجهات والهوية البصرية.
3. لا أحد يدخل في منطقة الثاني إلا بعد تنسيق واضح.
4. بعد أول ISO حقيقي ناجح نراجع إذا كان وقت rename الداخلي قد حان.

## قاعدة الدمج
- كل PR يجب أن يذكر الملفات التي لمسها.
- إذا كانت المهمة لمست ملفات خارج ملكية صاحبها، يجب ذكر السبب.
- إذا ظهر conflict، الأولوية لصاحب الملكية الأساسية لذلك المسار.

## أول تقسيم عملي جاهز الآن

### عبدالله يبدأ بـ
- `stable` build
- `stable` VM cycle
- `login-test` build
- `login-test` VM cycle

### محمد يبدأ بـ
- Welcome polish
- Update Center polish
- SDDM polish
- مراجعة نصوص `Lumina-OS` في الواجهات
