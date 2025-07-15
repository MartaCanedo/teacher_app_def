import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_model.dart';
import 'package:uuid/uuid.dart';

class MaterialController {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> addMaterial({
    required String titulo,
    required String descricao,
    required File file,
    required String disciplinaId,
    required String nomeArquivo,
    required String professorId,
  }) async {
    try {
      print(
        '[DEBUG] Salvando material: disciplinaId=$disciplinaId, professorId=$professorId, nomeArquivo=$nomeArquivo',
      );

      // Validations
      if (titulo.trim().isEmpty) {
        throw Exception('Título não pode estar vazio');
      }
      if (disciplinaId.trim().isEmpty) {
        throw Exception('ID da disciplina inválido');
      }
      if (professorId.trim().isEmpty) {
        throw Exception('ID do professor inválido');
      }
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Arquivo está vazio');
      }

      final base64Str = base64Encode(bytes);
      final id = _uuid.v4();
      
      final materialData = {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'base64Arquivo': base64Str,
        'nomeArquivo': nomeArquivo,
        'dataCriacao': DateTime.now().toIso8601String(),
        'disciplinaId': disciplinaId,
        'professorId': professorId,
      };
      
      await _firestore.collection('materiais').doc(id).set(materialData);
      print('[DEBUG] Material salvo com sucesso!');
    } catch (e) {
      print('[DEBUG] Erro ao salvar material: $e');
      rethrow;
    }
  }

  Future<List<MaterialModel>> getMateriais(
    String disciplinaId,
    String professorId,
  ) async {
    try {
      print(
        '[DEBUG] Buscando materiais: disciplinaId=$disciplinaId, professorId=$professorId',
      );
      final snap =
          await _firestore
              .collection('materiais')
              .where('disciplinaId', isEqualTo: disciplinaId)
              .where('professorId', isEqualTo: professorId)
              .orderBy('dataCriacao', descending: true)
              .get();
      print('[DEBUG] Materiais encontrados: ${snap.docs.length}');
      for (var doc in snap.docs) {
        print(
          '[DEBUG] Material: id=${doc['id']}, titulo=${doc['titulo']}, professorId=${doc['professorId']}, disciplinaId=${doc['disciplinaId']}',
        );
      }
      final materiais =
          snap.docs.map((doc) => MaterialModel.fromMap(doc.data())).toList();
      print(
        '[DEBUG] Lista de materiais retornada para a tela: ${materiais.length}',
      );
      return materiais;
    } catch (e) {
      print('[DEBUG] Erro ao buscar materiais: $e');
      return [];
    }
  }

  Future<void> updateMaterial(
    String id,
    String titulo,
    String descricao,
  ) async {
    try {
      await _firestore.collection('materiais').doc(id).update({
        'titulo': titulo,
        'descricao': descricao,
      });
    } catch (e) {
      print('[DEBUG] Erro ao atualizar material: $e');
      rethrow;
    }
  }

  Future<void> deleteMaterial(String id) async {
    try {
      await _firestore.collection('materiais').doc(id).delete();
    } catch (e) {
      print('[DEBUG] Erro ao deletar material: $e');
      rethrow;
    }
  }
}
