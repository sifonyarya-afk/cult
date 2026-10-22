import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'talk.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('Каталог услуг', style: cultHeadline(32)),
        const SizedBox(height: 8),
        const Text('Название, цена и длительность. Подробности и противопоказания — в карточке.'),
        const SizedBox(height: 16),
        for (final service in services) ...[
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

class DoctorsPage extends StatelessWidget {
  const DoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Врачи')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
