class TarefaModel {
  final String id;
  final String titulo;
  final String descricao;
  final String disciplinaId;
  final String professorId;
  final DateTime dataLimite;
  final DateTime dataPublicacao;
  final List<Map<String, String>>
  ficheiros; // [{nome: "arquivo.pdf", base64: "base64string"}]
  final Map<String, bool> entregas; // alunoId/nome : entregue
  final Map<String, List<Map<String, String>>>
  entregasFicheiros; // alunoId : [{nome: "arquivo.pdf", base64: "base64string"}]
  final String horaLimite; // formato HH:mm

  TarefaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.disciplinaId,
    required this.professorId,
    required this.dataLimite,
    required this.dataPublicacao,
    this.ficheiros = const [],
    required this.entregas,
    this.entregasFicheiros = const {},
    required this.horaLimite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'disciplinaId': disciplinaId,
      'professorId': professorId,
      'dataLimite': dataLimite.toIso8601String(),
      'dataPublicacao': dataPublicacao.toIso8601String(),
      'ficheiros': ficheiros,
      'entregas': entregas,
      'entregasFicheiros': entregasFicheiros,
      'horaLimite': horaLimite,
    };
  }

  factory TarefaModel.fromMap(Map<String, dynamic> map) {
    try {
      return TarefaModel(
        id: map['id'] ?? '',
        titulo: map['titulo'] ?? '',
        descricao: map['descricao'] ?? '',
        disciplinaId: map['disciplinaId'] ?? '',
        professorId: map['professorId'] ?? '',
        dataLimite: DateTime.parse(map['dataLimite']),
        dataPublicacao:
            map['dataPublicacao'] != null
                ? DateTime.parse(map['dataPublicacao'])
                : DateTime.now(),
        ficheiros: _parseFilesList(map['ficheiros']),
        entregas: _parseEntregasMap(map['entregas']),
        entregasFicheiros: _parseEntregasFicheirosMap(
          map['entregas'],
        ), // Usar o mesmo campo 'entregas'
        horaLimite: map['horaLimite'] ?? '23:59',
      );
    } catch (e) {
      print('Erro em TarefaModel.fromMap: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  static List<Map<String, String>> _parseFilesList(dynamic filesData) {
    if (filesData == null) return [];

    try {
      if (filesData is List) {
        final result = <Map<String, String>>[];
        for (final item in filesData) {
          if (item is String) {
            // Compatibilidade com dados antigos (apenas nome)
            result.add({'nome': item, 'base64': ''});
          } else if (item is Map) {
            // Dados novos (nome + base64)
            try {
              final map = Map<String, dynamic>.from(item);
              result.add({
                'nome': map['nome']?.toString() ?? '',
                'base64': map['base64']?.toString() ?? '',
              });
            } catch (e) {
              result.add({'nome': item.toString(), 'base64': ''});
            }
          } else {
            // Fallback para casos inesperados
            result.add({'nome': item.toString(), 'base64': ''});
          }
        }
        return result;
      }
    } catch (e) {
      print('Erro ao fazer parse da lista de ficheiros: $e');
    }

    return [];
  }

  static Map<String, bool> _parseEntregasMap(dynamic entregasData) {
    print('DEBUG _parseEntregasMap: $entregasData');
    if (entregasData == null) return {};

    try {
      if (entregasData is Map) {
        // Estrutura: alunoId -> bool
        return Map<String, bool>.from(entregasData);
      } else if (entregasData is List) {
        // Estrutura: [{alunoId: "id", fileName: "file", base64: "data", timestamp: "time"}]
        final result = <String, bool>{};
        for (final item in entregasData) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final alunoId = map['alunoId']?.toString();
            if (alunoId != null && alunoId.isNotEmpty) {
              result[alunoId] = true;
              print('DEBUG: Aluno $alunoId marcado como entregue');
            }
          }
        }
        print('DEBUG: Resultado entregas: $result');
        return result;
      }
    } catch (e) {
      print('Erro ao fazer parse do map de entregas: $e');
    }

    return {};
  }

  static Map<String, List<Map<String, String>>> _parseEntregasFicheirosMap(
    dynamic entregasFicheirosData,
  ) {
    print('DEBUG _parseEntregasFicheirosMap: $entregasFicheirosData');
    if (entregasFicheirosData == null) return {};

    try {
      if (entregasFicheirosData is Map) {
        // Estrutura: alunoId -> [{nome: "file", base64: "data"}]
        final result = <String, List<Map<String, String>>>{};
        entregasFicheirosData.forEach((key, value) {
          if (value is List) {
            final ficheiros = <Map<String, String>>[];
            for (final item in value) {
              if (item is Map) {
                try {
                  final map = Map<String, dynamic>.from(item);
                  ficheiros.add({
                    'nome': map['nome']?.toString() ?? '',
                    'base64': map['base64']?.toString() ?? '',
                  });
                } catch (e) {
                  print('Erro ao fazer parse do ficheiro da entrega: $e');
                }
              }
            }
            result[key.toString()] = ficheiros;
          }
        });
        return result;
      } else if (entregasFicheirosData is List) {
        // Estrutura: [{alunoId: "id", fileName: "file", base64: "data", timestamp: "time"}]
        final result = <String, List<Map<String, String>>>{};
        for (final item in entregasFicheirosData) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final alunoId = map['alunoId']?.toString();
            final fileName = map['fileName']?.toString();
            final base64Data = map['base64']?.toString();

            print(
              'DEBUG: Processando item: alunoId=$alunoId, fileName=$fileName',
            );

            if (alunoId != null &&
                alunoId.isNotEmpty &&
                fileName != null &&
                base64Data != null) {
              if (!result.containsKey(alunoId)) {
                result[alunoId] = [];
              }
              result[alunoId]!.add({'nome': fileName, 'base64': base64Data});
              print('DEBUG: Adicionado ficheiro $fileName para aluno $alunoId');
            }
          }
        }
        print('DEBUG: Resultado entregasFicheiros: $result');
        return result;
      }
    } catch (e) {
      print('Erro ao fazer parse do map de entregas ficheiros: $e');
    }

    return {};
  }
}
