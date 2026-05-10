// lib/core/services/certificate_service.dart
//
// Manages reading earned certificates from the DB and exporting
// a rendered certificate widget as a PNG to the device gallery.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../database/app_database.dart';

enum CertificateType {
  participation,
  completion,
  excellenceTop1,
  excellenceTop10,
  recognitionTop20,
  runnerUp,
}

class CertificateModel {
  final String id;
  final String moduleId;
  final String moduleTitle;
  final String certCode;
  final DateTime issuedAt;
  final double scorePct;
  final CertificateType type;

  const CertificateModel({
    required this.id,
    required this.moduleId,
    required this.moduleTitle,
    required this.certCode,
    required this.issuedAt,
    required this.scorePct,
    required this.type,
  });
}

class CertificateService {
  CertificateService._();
  static final CertificateService instance = CertificateService._();

  String _uid = 'anonymous';
  void setUserId(String uid) => _uid = uid;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<CertificateModel>> getEarnedCertificates() async {
    if (_uid == 'anonymous') return [];
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT lc.*, m.title as module_title
      FROM learner_certificates lc
      JOIN modules m ON lc.module_id = m.id
      WHERE lc.learner_id = ?
      ORDER BY lc.issued_at DESC
    ''', [_uid]);

    return rows.map((r) {
      final score = (r['score_pct'] as num).toDouble();
      return CertificateModel(
        id: r['id'] as String,
        moduleId: r['module_id'] as String,
        moduleTitle: r['module_title'] as String,
        certCode: r['cert_code'] as String,
        issuedAt: DateTime.parse(r['issued_at'] as String),
        scorePct: score,
        type: _inferType(score),
      );
    }).toList();
  }

  CertificateType _inferType(double scorePct) {
    if (scorePct >= 1.0) return CertificateType.excellenceTop1;
    if (scorePct >= 0.90) return CertificateType.excellenceTop10;
    if (scorePct >= 0.80) return CertificateType.recognitionTop20;
    if (scorePct >= 0.70) return CertificateType.completion;
    return CertificateType.participation;
  }

  String typeLabel(CertificateType type) {
    switch (type) {
      case CertificateType.participation:  return 'Certificate of Participation';
      case CertificateType.completion:     return 'Certificate of Completion';
      case CertificateType.excellenceTop1: return 'Certificate of Excellence — Rank #1';
      case CertificateType.excellenceTop10:return 'Certificate of Excellence — Top 10';
      case CertificateType.recognitionTop20:return 'Certificate of Recognition — Top 20';
      case CertificateType.runnerUp:       return 'Certificate of Recognition — Runner-up';
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  /// Renders the widget captured by [key] as a PNG
  /// and saves it to the device's photo gallery.
  /// Returns true on success.
  Future<bool> exportToPng(GlobalKey key, String fileName) async {
    try {
      final boundary = key.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return false;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: fileName,
      );
      return result['isSuccess'] == true;
    } catch (_) {
      return false;
    }
  }
}
