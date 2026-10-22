import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';
import 'info.dart';
import 'talk.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _query = TextEditingController();
  var _chip = 'Все услуги';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matchesChip(String category, String group) {
    final text = '${category.toLowerCase()} ${group.toLowerCase()}';
    return switch (_chip) {
      'Все услуги' => true,
      'Эстетика' => text.contains('эстет') || text.contains('уход') || text.contains('увлаж') || text.contains('точн') || text.contains('клинич'),
      'Инъекции' => text.contains('инъек'),
      'Инфузии' => text.contains('инфуз') || text.contains('велнес') || text.contains('iv'),
      'Аппараты' => text.contains('аппарат') || text.contains('rf') || text.contains('точн'),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final live = store.catalogLive;
    final local = store.catalogServices;
    final gender = store.gender;
    final needle = _query.text.trim().toLowerCase();
    final chips = const ['Все услуги', 'Эстетика', 'Инъекции', 'Инфузии', 'Аппараты'];

    final liveFiltered = live.where((service) {
      if (!_matchesChip(service.category, service.category)) return false;
      if (needle.isEmpty) return true;
      return service.title.toLowerCase().contains(needle) || service.category.toLowerCase().contains(needle);
    }).toList();
    final localFiltered = local.where((service) {
      if (!_matchesChip(service.category, service.group)) return false;
      if (needle.isEmpty) return true;
      return service.title.toLowerCase().contains(needle) ||
          service.category.toLowerCase().contains(needle) ||
          service.blurb.toLowerCase().contains(needle);
    }).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            const Text(
              'ИНДИВИДУАЛЬНЫЙ ПОДХОД',
              textAlign: TextAlign.center,
              style: TextStyle(color: Cult.muted, letterSpacing: 2, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Text(
              'Консультация, диагностика и персональные программы',
              style: cultHeadline(28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              gender == null
                  ? 'Протоколы по диагностике кожи и задачам организма.'
                  : 'Каталог ${gender.forLabel}: эстетика, инъекции и инфузии.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Cult.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            CultButton(label: 'Записаться', onPressed: () => pushPage(context, const BookingPage())),
            if (gender != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Женские')),
                      selected: gender == ClientGender.woman,
                      onSelected: (_) => store.setGender(ClientGender.woman),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Мужские')),
                      selected: gender == ClientGender.man,
                      onSelected: (_) => store.setGender(ClientGender.man),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _query,
              decoration: const InputDecoration(
                hintText: 'Поиск процедур...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chip = chips[index];
                  final selected = _chip == chip;
                  return FilterChip(
                    label: Text(chip),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: Cult.ink,
                    labelStyle: TextStyle(color: selected ? Colors.white : Cult.ink),
                    backgroundColor: const Color(0xFFF3EFEA),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _chip = chip),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(label: const Text('Аппаратная'), onPressed: () => pushPage(context, const CategoryHubPage(slug: 'hardware'))),
                ActionChip(label: const Text('Инъекции'), onPressed: () => pushPage(context, const CategoryHubPage(slug: 'injections'))),
                ActionChip(label: const Text('Инфузии'), onPressed: () => pushPage(context, const CategoryHubPage(slug: 'infusions'))),
                ActionChip(label: const Text('Наука'), onPressed: () => pushPage(context, const CategoryHubPage(slug: 'science'))),
              ],
            ),
            if (store.syncing || (store.yclientsReady && store.liveServices.isEmpty && store.liveError.isEmpty))
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator()),
            if (store.liveError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(store.liveError, style: const TextStyle(color: Cult.error)),
              TextButton(onPressed: store.refreshCatalog, child: const Text('Обновить прайс')),
            ],
            const SizedBox(height: 16),
            if (liveFiltered.isNotEmpty)
              for (final service in liveFiltered) ...[
                InkWell(
                  onTap: () => pushPage(context, LiveServicePage(service: service)),
                  child: CultCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (service.category.isEmpty ? 'Филиал' : service.category).toUpperCase(),
                          style: const TextStyle(color: Cult.primary, letterSpacing: 1.1, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(service.title, style: cultHeadline(22)),
                        if (service.comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(service.comment, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cult.muted)),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          [
                            service.priceLabel,
                            if (service.durationLabel.isNotEmpty) service.durationLabel,
                          ].join(' · '),
                          style: const TextStyle(color: Cult.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ]
            else if (localFiltered.isEmpty)
              const Text('Ничего не найдено. Смените фильтр или запрос.')
            else
              for (final service in localFiltered) ...[
                InkWell(
                  onTap: () => pushPage(context, ServicePage(service: service)),
                  child: CultCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CultImage(service.image, aspect: 16 / 10, radius: 16),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.category.toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1.1, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(service.title, style: cultHeadline(22)),
                              const SizedBox(height: 6),
                              Text(service.blurb, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cult.muted)),
                              const SizedBox(height: 8),
                              Text('${service.priceLabel} · ${service.duration}', style: const TextStyle(color: Cult.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'services-book',
            backgroundColor: Cult.ink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onPressed: () => pushPage(context, const BookingPage()),
            child: const Icon(Icons.calendar_month_outlined),
          ),
        ),
      ],
    );
  }
}

class LiveServicePage extends StatelessWidget {
  const LiveServicePage({super.key, required this.service});

  final YcService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text((service.category.isEmpty ? 'Филиал' : service.category).toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(service.title, style: cultHeadline(30)),
          if (service.durationLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(service.durationLabel, style: const TextStyle(color: Cult.muted)),
          ],
          const SizedBox(height: 14),
          if (service.comment.isNotEmpty) Text(service.comment, maxLines: 5, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          Text(service.priceLabel, style: cultHeadline(24)),
          const SizedBox(height: 16),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, BookingPage(initialService: service.title))),
        ],
      ),
    );
  }
}

class ServicePage extends StatelessWidget {
  const ServicePage({super.key, required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CultImage(service.image, aspect: 4 / 5, radius: 18),
          const SizedBox(height: 16),
          Text(service.category.toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(service.title, style: cultHeadline(30)),
          Text('${service.duration} · ${service.priceLabel}', style: const TextStyle(color: Cult.muted)),
          const SizedBox(height: 12),
          Text(service.blurb, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          Text('Как проходит', style: cultHeadline(22)),
          for (var i = 0; i < service.steps.length; i++)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('0${i + 1}  ${service.steps[i]}')),
          const SizedBox(height: 16),
          Text('Важно', style: cultHeadline(22)),
          for (final item in service.contraindications.take(3))
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('· $item', style: const TextStyle(color: Cult.muted))),
          const SizedBox(height: 20),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, BookingPage(initialService: service.title))),
        ],
      ),
    );
  }
}

class CategoryHubPage extends StatelessWidget {
  const CategoryHubPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final meta = switch (slug) {
      'hardware' => (
          title: 'Аппаратная косметология',
          eyebrow: 'ТЕХНОЛОГИИ',
          lead: 'RF, IPL и SMAS-лифтинг. Плотность кожи без долгой реабилитации.',
          image: 'science',
        ),
      'injections' => (
          title: 'Инъекционная косметология',
          eyebrow: 'ИНЪЕКЦИИ',
          lead: 'Ботулинотерапия, контур и мезо. Точные дозы под вашу анатомию.',
          image: 'botox',
        ),
      'infusions' => (
          title: 'Инфузионная терапия',
          eyebrow: 'ВЕЛНЕС',
          lead: 'Капельницы для энергии, иммунитета и сияния кожи.',
          image: 'iv',
        ),
      'science' => (
          title: 'Наука CULT',
          eyebrow: 'КЛИНИКА',
          lead: 'Протоколы, кейсы и разборы технологий филиала в Сочи.',
          image: 'scan',
        ),
      _ => (
          title: 'Услуги',
          eyebrow: 'CULT',
          lead: 'Подборка процедур филиала.',
          image: 'interior',
        ),
    };

    final local = store.catalogServices.where((service) {
      final text = '${service.category} ${service.group} ${service.title}'.toLowerCase();
      return switch (slug) {
        'hardware' => text.contains('rf') || text.contains('точн') || text.contains('аппарат'),
        'injections' => text.contains('инъек') || text.contains('бот') || text.contains('мезо') || text.contains('контур'),
        'infusions' => text.contains('инфуз') || text.contains('iv') || text.contains('витамин') || text.contains('велнес'),
        'science' => false,
        _ => true,
      };
    }).toList();

    final live = store.catalogLive.where((service) {
      final text = '${service.category} ${service.title}'.toLowerCase();
      return switch (slug) {
        'hardware' => text.contains('rf') || text.contains('морф') || text.contains('ультра') || text.contains('аппарат'),
        'injections' => text.contains('инъек') || text.contains('бот') || text.contains('филлер') || text.contains('мезо'),
        'infusions' => text.contains('инфуз') || text.contains('капел') || text.contains('iv') || text.contains('nad'),
        'science' => false,
        _ => true,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CultImage(meta.image, aspect: 16 / 10, radius: 18),
          const SizedBox(height: 16),
          Text(meta.eyebrow, style: const TextStyle(color: Cult.secondary, letterSpacing: 1.6, fontSize: 11)),
          const SizedBox(height: 6),
          Text(meta.title, style: cultHeadline(30)),
          const SizedBox(height: 8),
          Text(meta.lead, style: const TextStyle(color: Cult.muted, height: 1.4)),
          const SizedBox(height: 16),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, const BookingPage())),
          if (slug == 'hardware') ...[
            const SizedBox(height: 20),
            Text('Аппараты', style: cultHeadline(22)),
            const SizedBox(height: 8),
            for (final device in devices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => pushPage(context, DevicePage(device: device)),
                  child: CultCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device.title, style: cultHeadline(20)),
                              Text('${device.meta} · ${device.price}', style: const TextStyle(color: Cult.primary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Cult.muted),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          if (slug == 'science') ...[
            const SizedBox(height: 20),
            Text('Разборы', style: cultHeadline(22)),
            const SizedBox(height: 8),
            for (final article in articles.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => pushPage(context, ArticlePage(article: article)),
                  child: CultCard(
                    child: Text(article.title, style: cultHeadline(20)),
                  ),
                ),
              ),
            TextButton(onPressed: () => pushPage(context, const CasesPage()), child: const Text('Клинические кейсы')),
          ] else if (live.isNotEmpty || local.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Процедуры', style: cultHeadline(22)),
            const SizedBox(height: 8),
            for (final service in live)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => pushPage(context, LiveServicePage(service: service)),
                  child: CultCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.title, style: cultHeadline(20)),
                        Text(service.priceLabel, style: const TextStyle(color: Cult.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            for (final service in local)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => pushPage(context, ServicePage(service: service)),
                  child: CultCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.title, style: cultHeadline(20)),
                        Text('${service.priceLabel} · ${service.duration}', style: const TextStyle(color: Cult.primary)),
                        const SizedBox(height: 4),
                        Text(service.blurb, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cult.muted)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class DevicePage extends StatelessWidget {
  const DevicePage({super.key, required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аппарат')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const CultImage('science', aspect: 16 / 10, radius: 18),
          const SizedBox(height: 16),
          const Text('ОБОРУДОВАНИЕ', style: TextStyle(color: Cult.secondary, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 6),
          Text(device.title, style: cultHeadline(30)),
          Text('${device.meta} · ${device.price}', style: const TextStyle(color: Cult.muted)),
          const SizedBox(height: 12),
          Text(device.text, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 20),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, BookingPage(initialService: device.title))),
        ],
      ),
    );
  }
}

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ClinicScope.of(context);
      if (store.liveStaff.isEmpty) store.refreshStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final live = store.liveStaff;
    return Scaffold(
      appBar: AppBar(title: const Text('Специалисты')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Команда CULT', style: cultHeadline(28)),
          const SizedBox(height: 6),
          const Text('Врачи филиала в Сочи. Запись и чат — в карточке.', style: TextStyle(color: Cult.muted)),
          const SizedBox(height: 16),
          if (live.isEmpty && store.yclientsReady) const LinearProgressIndicator(),
          if (live.isNotEmpty)
            for (final doctor in live)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => pushPage(context, LiveDoctorPage(doctor: doctor)),
                  child: CultCard(
                    child: Row(
                      children: [
                        _Avatar(url: doctor.avatar, name: doctor.name),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctor.name, style: cultHeadline(20)),
                              Text(
                                doctor.specialization.isEmpty ? 'Врач филиала' : doctor.specialization,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text('CULT · Сочи', style: TextStyle(color: Cult.muted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Cult.muted),
                      ],
                    ),
                  ),
                ),
              )
          else
            for (final doctor in doctors)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => pushPage(context, DoctorPage(doctor: doctor)),
                  child: CultCard(
                    child: Row(
                      children: [
                        SizedBox(width: 72, child: CultImage(doctor.image, aspect: 1, radius: 16)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctor.name, style: cultHeadline(20)),
                              Text(doctor.role),
                              Text(doctor.exp, style: const TextStyle(color: Cult.muted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Cult.muted),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class LiveDoctorPage extends StatelessWidget {
  const LiveDoctorPage({super.key, required this.doctor});

  final YcStaff doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doctor.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: _Avatar(url: doctor.avatar, name: doctor.name, size: 160)),
          const SizedBox(height: 12),
          Text((doctor.specialization.isEmpty ? 'Врач' : doctor.specialization).toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1.1)),
          Text(doctor.name, style: cultHeadline(28)),
          const Text('CULT · Сочи, Черноморская, 6'),
          const SizedBox(height: 12),
          Text(doctor.about.isEmpty ? 'Врач филиала CULT. Запись и консультации — в приложении.' : doctor.about),
          const SizedBox(height: 16),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, const BookingPage())),
          TextButton(onPressed: () => pushPage(context, const ChatThreadPage(contactId: 'specialist')), child: const Text('Чат с доктором')),
        ],
      ),
    );
  }
}

class DoctorPage extends StatelessWidget {
  const DoctorPage({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doctor.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CultImage(doctor.image, aspect: 1, radius: 16),
          const SizedBox(height: 12),
          Text(doctor.role.toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1.1)),
          Text(doctor.name, style: cultHeadline(28)),
          Text('Опыт ${doctor.exp}'),
          const SizedBox(height: 12),
          Text(doctor.about),
          const SizedBox(height: 12),
          Text('Образование', style: cultHeadline(22)),
          const SizedBox(height: 6),
          Text(doctor.education),
          const SizedBox(height: 12),
          Text('Отзывы', style: cultHeadline(22)),
          for (final review in doctor.reviews) Padding(padding: const EdgeInsets.only(top: 8), child: Text('«$review»')),
          const SizedBox(height: 20),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, const BookingPage())),
          TextButton(onPressed: () => pushPage(context, const ChatThreadPage(contactId: 'specialist')), child: const Text('Чат с доктором')),
        ],
      ),
    );
  }
}

class EquipmentPage extends StatelessWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оборудование')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CultImage('science', aspect: 16 / 9, radius: 18),
          const SizedBox(height: 14),
          Text('Аппаратная косметология', style: cultHeadline(28)),
          const SizedBox(height: 6),
          const Text('Технологии филиала: плотность кожи, овал и тон.', style: TextStyle(color: Cult.muted)),
          const SizedBox(height: 16),
          for (final device in devices)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => pushPage(context, DevicePage(device: device)),
                child: CultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.title, style: cultHeadline(22)),
                      Text('${device.meta} · ${device.price}', style: const TextStyle(color: Cult.primary)),
                      const SizedBox(height: 6),
                      Text(device.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cult.muted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, this.size = 72});

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: Cult.sand,
      child: Text(name.isEmpty ? 'C' : name.substring(0, 1).toUpperCase(), style: cultHeadline(size / 3)),
    );
    if (url.isEmpty) return SizedBox(width: size, height: size, child: fallback);
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
