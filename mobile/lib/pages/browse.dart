import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';
import 'talk.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final live = store.catalogLive;
    final local = store.catalogServices;
    final gender = store.gender;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(gender?.servicesTitle ?? 'Каталог услуг', style: cultHeadline(32)),
        const SizedBox(height: 8),
        Text(
          live.isNotEmpty
              ? 'Услуги филиала CULT в Сочи${gender == null ? '' : ' · ${gender.forLabel}'}.'
              : 'Название, цена и длительность. Подробности — в карточке.',
        ),
        if (gender != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Женские'),
                selected: gender == ClientGender.woman,
                onSelected: (_) => store.setGender(ClientGender.woman),
              ),
              ChoiceChip(
                label: const Text('Мужские'),
                selected: gender == ClientGender.man,
                onSelected: (_) => store.setGender(ClientGender.man),
              ),
            ],
          ),
        ],
        if (store.syncing || (store.yclientsReady && store.liveServices.isEmpty && store.liveError.isEmpty))
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator()),
        if (store.liveError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(store.liveError, style: const TextStyle(color: Cult.error)),
          TextButton(onPressed: store.refreshCatalog, child: const Text('Обновить прайс')),
        ],
        const SizedBox(height: 16),
        if (live.isNotEmpty)
          for (final service in live) ...[
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
                      Text(service.comment, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      [
                        service.priceLabel,
                        if (service.durationLabel.isNotEmpty) service.durationLabel,
                      ].join(' · '),
                      style: const TextStyle(color: Cult.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ]
        else if (local.isEmpty)
          const Text('Для этого профиля услуг пока нет.')
        else
          for (final service in local) ...[
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
                          Text(service.blurb),
                          const SizedBox(height: 8),
                          Text('${service.priceLabel} · ${service.duration}', style: const TextStyle(color: Cult.primary)),
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
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, BookingPage(initialService: service.title))),
          const SizedBox(height: 16),
          Text((service.category.isEmpty ? 'Филиал' : service.category).toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1.2)),
          Text(service.title, style: cultHeadline(30)),
          if (service.durationLabel.isNotEmpty) Text(service.durationLabel, style: const TextStyle(color: Cult.muted)),
          const SizedBox(height: 12),
          if (service.comment.isNotEmpty) Text(service.comment),
          const SizedBox(height: 12),
          Text('Стоимость ${service.priceLabel}', style: cultHeadline(22)),
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
          CultImage(service.image, aspect: 4 / 5, radius: 16),
          const SizedBox(height: 16),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, BookingPage(initialService: service.title))),
          const SizedBox(height: 16),
          Text(service.category.toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1.2)),
          Text(service.title, style: cultHeadline(30)),
          const SizedBox(height: 4),
          Text(service.duration, style: const TextStyle(color: Cult.muted)),
          const SizedBox(height: 12),
          Text(service.long),
          const SizedBox(height: 16),
          Text('Как проходит', style: cultHeadline(22)),
          for (var i = 0; i < service.steps.length; i++) Padding(padding: const EdgeInsets.only(top: 8), child: Text('0${i + 1}  ${service.steps[i]}')),
          const SizedBox(height: 16),
          Text('Противопоказания', style: cultHeadline(22)),
          for (final item in service.contraindications) Padding(padding: const EdgeInsets.only(top: 6), child: Text(item)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => openExternal('https://www.youtube.com/results?search_query=${Uri.encodeComponent('${service.title} CULT Clinic')}'),
            child: const Text('Видео процедуры на YouTube'),
          ),
          Text('Стоимость ${service.priceLabel}', style: cultHeadline(22)),
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
      appBar: AppBar(title: const Text('Врачи')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                              Text(doctor.specialization.isEmpty ? 'Врач филиала' : doctor.specialization),
                              Text('CULT · Сочи', style: const TextStyle(color: Cult.muted)),
                            ],
                          ),
                        ),
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
                        SizedBox(width: 72, child: CultImage(doctor.image, aspect: 1, radius: 36)),
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
          const CultImage('science', aspect: 16 / 9, radius: 16),
          const SizedBox(height: 16),
          for (final device in devices)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => pushPage(context, BookingPage(initialService: device.title)),
                child: CultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.title, style: cultHeadline(22)),
                      Text('${device.meta} · ${device.price}', style: const TextStyle(color: Cult.primary)),
                      const SizedBox(height: 6),
                      Text(device.text),
                      const SizedBox(height: 8),
                      const Text('Записаться', style: TextStyle(color: Cult.primary, fontWeight: FontWeight.w600)),
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
