import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';
import 'categories.dart';
import 'talk.dart';

export 'categories.dart'
    show CategoryHubPage, DevicePage, HardwareCosmeticsPage;

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
      'Эстетика' =>
        text.contains('эстет') ||
            text.contains('уход') ||
            text.contains('увлаж') ||
            text.contains('клинич'),
      'Инъекции' => text.contains('инъек'),
      'Велнес' =>
        text.contains('инфуз') ||
            text.contains('велнес') ||
            text.contains('iv') ||
            text.contains('витамин'),
      'Авторский' =>
        text.contains('автор') ||
            text.contains('точн') ||
            text.contains('rf') ||
            text.contains('скульпт'),
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
    final chips = const [
      'Все услуги',
      'Эстетика',
      'Инъекции',
      'Велнес',
      'Авторский',
    ];

    final liveFiltered = live.where((service) {
      if (!_matchesChip(service.category, service.category)) return false;
      if (needle.isEmpty) return true;
      return service.title.toLowerCase().contains(needle) ||
          service.category.toLowerCase().contains(needle);
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
        RefreshIndicator(
          color: Cult.primary,
          onRefresh: () => store.refreshCatalog(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
            children: [
              const Text(
                'ИНДИВИДУАЛЬНЫЙ ПОДХОД',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Cult.muted,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
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
              CultButton(
                label: 'Записаться',
                onPressed: () => pushPage(context, const BookingPage()),
              ),
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
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Cult.ink,
                      ),
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
                  ActionChip(
                    label: const Text('Аппаратная'),
                    onPressed: () => pushPage(
                      context,
                      const CategoryHubPage(slug: 'hardware'),
                    ),
                  ),
                  ActionChip(
                    label: const Text('Инъекции'),
                    onPressed: () => pushPage(
                      context,
                      const CategoryHubPage(slug: 'injections'),
                    ),
                  ),
                  ActionChip(
                    label: const Text('Инфузии'),
                    onPressed: () => pushPage(
                      context,
                      const CategoryHubPage(slug: 'infusions'),
                    ),
                  ),
                  ActionChip(
                    label: const Text('Наука'),
                    onPressed: () => pushPage(
                      context,
                      const CategoryHubPage(slug: 'science'),
                    ),
                  ),
                ],
              ),
              if (store.syncing ||
                  (store.yclientsReady &&
                      store.liveServices.isEmpty &&
                      store.liveError.isEmpty))
                const CultLoading(label: 'Загружаем прайс филиала…'),
              if (store.liveError.isNotEmpty)
                CultErrorBanner(
                  message: store.liveError,
                  onRetry: store.refreshCatalog,
                  retryLabel: 'Обновить прайс',
                ),
              const SizedBox(height: 16),
              if (liveFiltered.isNotEmpty)
                for (final service in liveFiltered) ...[
                  InkWell(
                    onTap: () =>
                        pushPage(context, LiveServicePage(service: service)),
                    child: CultCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (service.category.isEmpty
                                    ? 'Филиал'
                                    : service.category)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Cult.primary,
                              letterSpacing: 1.1,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(service.title, style: cultHeadline(22)),
                          if (service.comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              service.comment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Cult.muted),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            [
                              service.priceLabel,
                              if (service.durationLabel.isNotEmpty)
                                service.durationLabel,
                            ].join(' · '),
                            style: const TextStyle(
                              color: Cult.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]
              else if (localFiltered.isEmpty)
                CultEmpty(
                  title: 'Ничего не найдено',
                  note: 'Смените фильтр или запрос — каталог обновится.',
                  actionLabel: 'Сбросить фильтр',
                  onAction: () => setState(() {
                    _chip = 'Все услуги';
                    _query.clear();
                  }),
                )
              else
                for (final service in localFiltered) ...[
                  InkWell(
                    onTap: () =>
                        pushPage(context, ServicePage(service: service)),
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
                                Text(
                                  service.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: Cult.primary,
                                    letterSpacing: 1.1,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(service.title, style: cultHeadline(22)),
                                const SizedBox(height: 6),
                                Text(
                                  service.blurb,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Cult.muted),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${service.priceLabel} · ${service.duration}',
                                  style: const TextStyle(
                                    color: Cult.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'services-book',
            backgroundColor: Cult.ink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
          Text(
            (service.category.isEmpty ? 'Филиал' : service.category)
                .toUpperCase(),
            style: const TextStyle(color: Cult.primary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          Text(service.title, style: cultHeadline(30)),
          if (service.durationLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              service.durationLabel,
              style: const TextStyle(color: Cult.muted),
            ),
          ],
          const SizedBox(height: 14),
          if (service.comment.isNotEmpty)
            Text(
              service.comment,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.4),
            ),
          const SizedBox(height: 16),
          Text(service.priceLabel, style: cultHeadline(24)),
          const SizedBox(height: 16),
          CultButton(
            label: 'Записаться',
            onPressed: () =>
                pushPage(context, BookingPage(initialService: service.title)),
          ),
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
          Text(
            service.category.toUpperCase(),
            style: const TextStyle(color: Cult.primary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(service.title, style: cultHeadline(30)),
          Text(service.duration, style: const TextStyle(color: Cult.muted)),
          const SizedBox(height: 16),
          const CultSectionLabel('Результат'),
          for (final item in service.results)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Cult.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: const TextStyle(height: 1.35)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const CultSectionLabel('Как проходит'),
          for (var i = 0; i < service.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${i + 1}.  ${service.steps[i]}',
                style: const TextStyle(height: 1.35),
              ),
            ),
          const SizedBox(height: 18),
          const CultSectionLabel('Стоимость процедуры'),
          const SizedBox(height: 8),
          Text(
            service.priceLabel,
            style: cultHeadline(28).copyWith(color: Cult.primary),
          ),
          const SizedBox(height: 22),
          CultButton(
            label: 'Записаться',
            onPressed: () =>
                pushPage(context, BookingPage(initialService: service.title)),
          ),
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
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ClinicScope.of(context);
      if (store.liveStaff.isEmpty) store.refreshStaff();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final needle = _query.text.trim().toLowerCase();
    final live = store.liveStaff.where((doctor) {
      if (needle.isEmpty) return true;
      final hay = '${doctor.name} ${doctor.specialization}'.toLowerCase();
      return hay.contains(needle);
    }).toList();
    final local = doctors.where((doctor) {
      if (needle.isEmpty) return true;
      final hay = '${doctor.name} ${doctor.role}'.toLowerCase();
      return hay.contains(needle);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Специалисты')),
      body: RefreshIndicator(
        color: Cult.primary,
        onRefresh: () async {
          await store.refreshStaff();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Команда CULT', style: cultHeadline(28)),
            const SizedBox(height: 6),
            const Text(
              'Врачи филиала в Сочи. Запись и чат — в карточке.',
              style: TextStyle(color: Cult.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _query,
              decoration: const InputDecoration(
                hintText: 'Имя или специализация',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (store.liveStaff.isEmpty && store.yclientsReady)
              const CultLoading(label: 'Загружаем специалистов…'),
            if (live.isNotEmpty)
              for (final doctor in live)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () =>
                        pushPage(context, LiveDoctorPage(doctor: doctor)),
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
                                  doctor.specialization.isEmpty
                                      ? 'Врач филиала'
                                      : doctor.specialization,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'CULT · Сочи',
                                  style: TextStyle(color: Cult.muted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Cult.muted),
                        ],
                      ),
                    ),
                  ),
                )
            else if (local.isEmpty)
              CultEmpty(
                title: 'Никого не найдено',
                note: 'Смените запрос — покажем врачей филиала.',
                actionLabel: 'Сбросить',
                onAction: () => setState(() => _query.clear()),
              )
            else
              for (final doctor in local)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => pushPage(context, DoctorPage(doctor: doctor)),
                    child: CultCard(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: CultImage(
                              doctor.image,
                              aspect: 1,
                              radius: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctor.name, style: cultHeadline(20)),
                                Text(doctor.role),
                                Text(
                                  doctor.exp,
                                  style: const TextStyle(color: Cult.muted),
                                ),
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
      ),
    );
  }
}

class LiveDoctorPage extends StatelessWidget {
  const LiveDoctorPage({super.key, required this.doctor});

  final YcStaff doctor;

  @override
  Widget build(BuildContext context) {
    final role = doctor.specialization.isEmpty
        ? 'Врач филиала'
        : doctor.specialization;
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: _Avatar(url: doctor.avatar, name: doctor.name, size: 120),
          ),
          const SizedBox(height: 14),
          Text(
            doctor.name,
            style: cultHeadline(28),
            textAlign: TextAlign.center,
          ),
          Text(
            role.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Cult.primary,
              letterSpacing: 1.3,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'CULT · Сочи, Черноморская, 6',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cult.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Cult.gold,
              foregroundColor: Cult.ink,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => pushPage(
              context,
              const ChatThreadPage(contactId: 'specialist'),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text(
              'ЧАТ С ВРАЧОМ',
              style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            doctor.about.isEmpty
                ? 'Врач филиала CULT. Запись и консультации — в приложении.'
                : doctor.about,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          CultButton(
            label: 'Записаться',
            onPressed: () => pushPage(context, const BookingPage()),
          ),
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
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Cult.sand, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: CultImage(doctor.image, aspect: 1, radius: 0),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            doctor.name,
            style: cultHeadline(28),
            textAlign: TextAlign.center,
          ),
          Text(
            doctor.role.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Cult.primary,
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Cult.gold,
              foregroundColor: Cult.ink,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => pushPage(
              context,
              const ChatThreadPage(contactId: 'specialist'),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text(
              'ЧАТ С ВРАЧОМ',
              style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 22),
          const CultSectionLabel('Видео-приветствие'),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openExternal(
              'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${doctor.name} CULT Clinic')}',
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CultImage(doctor.image, aspect: 16 / 9, radius: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Cult.ink.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Text(
                    'Введение · ${doctor.role} (2:45)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(doctor.exp, 'лет опыта'),
              const SizedBox(width: 12),
              const _Stat('4.9 ★', 'рейтинг'),
            ],
          ),
          const SizedBox(height: 18),
          const CultSectionLabel('Образование'),
          const SizedBox(height: 8),
          Text(doctor.education, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          const CultSectionLabel('О специалисте'),
          const SizedBox(height: 8),
          Text(
            doctor.about,
            style: const TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          const CultSectionLabel('Отзывы'),
          for (final review in doctor.reviews.take(2))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CultCard(
                child: Text('«$review»', style: const TextStyle(height: 1.35)),
              ),
            ),
          const SizedBox(height: 20),
          CultButton(
            label: 'Записаться',
            onPressed: () => pushPage(context, const BookingPage()),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFEA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: cultHeadline(22)),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Cult.muted,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentPage extends StatelessWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HardwareCosmeticsPage();
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
      child: Text(
        name.isEmpty ? 'C' : name.substring(0, 1).toUpperCase(),
        style: cultHeadline(size / 3),
      ),
    );
    if (url.isEmpty)
      return SizedBox(width: size, height: size, child: fallback);
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
