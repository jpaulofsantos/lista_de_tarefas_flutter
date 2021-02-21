import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; //1 - importando material
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart'; //5 - importando path_provider (pubspec.yaml)

void main() { //2 - add main()
  runApp(MaterialApp( //2.1 - MaterialApp
    home: Home(), //4 - Apontando o home: para a classe Home
  )); // runApp
}

class Home extends StatefulWidget { //3 - stf, nomeando a classe como Home
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController(); // 16 -controller para o textfield

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved = Map(); // 26 - criando map para o dissmisable

  int _lastRemovedPosition;

  @override
  void initState() { // 24 - ctrl+o -> init state
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data); //25 - decode na lista
      });
    });

  } //8 - criando a lista de tarefas


  void _addToDoList() {  // 15 - criando a função para preencher a lista
    setState(() {

      Map<String, dynamic> newToDo = Map(); //19 - criando o Map vazio

      newToDo["title"] = _toDoController.text; //20 - pegando o texto do texfield
      _toDoController.text = ""; //21 - após pegar o texto, setar o campo como vazio
      newToDo["ok"] = false; //22 - marcando o campo como desmarcado
      _toDoList.add(newToDo); //23 - add mapa na lista
      _saveData();
      //print(_toDoList);
    });
  }

  Future<Null> _refresh() async { //24 - declarando a função para ordenar a lista pelos itens "checked"
    await Future.delayed(Duration(seconds: 1)); //25 aguardando 1s para ordenar

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if (!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // L1 - Iniciando o layout
      appBar: AppBar( // L2 - barra superior
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column( // L3 - corpo do APP (coluna com linhas)
        children: <Widget>[
          Container( // L4 - container responsável pelo espaçamento da área da linha (referente às bordas e linha inferior
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row( // L5 - linha (dentro da linha contêm um textfield e um botão
              children: <Widget>[
                Expanded( //L7 criando o expanded para definir o tamanho do TextField
                    child: TextField(
                      controller: _toDoController, // 17 - add controller no textfiled
                      decoration: InputDecoration(
                          labelText: "Nova tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)
                      ),
                    )
                ),
                RaisedButton( //L6 - criando o botão
                    color: Colors.blueAccent,
                    child: Text("ADD"),
                    textColor: Colors.white,
                    onPressed: _addToDoList,
                )
              ],
            ),
          ),
          Expanded( //L7 - gerencia o tamanho da lista que aparece na tela
            child: RefreshIndicator( // L21 - refresh para ordenar a lista pelos itens checked
              onRefresh: _refresh,
              child: ListView.builder( //L8 - renderiza elementos que estão sendo mostrados
                  padding: EdgeInsets.only(top: 10.0), //L9 - distancia da list e Row
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) { //L10 - itens da lista sendo mostrado no momento
    return Dismissible( // L11 - widget que permite arrastar para direita e excluir o item
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), // L19 - setando uma key para cada item deletado
      background: Container( // L12 - Container para criar a faixa para excluir
        color: Colors.red, // L13 - cor de fundo vermelho
        child: Align( // L14 - alinhando na esquerda o icone da lixeira
          alignment: Alignment(-0.9, 0.0), //L15 - definindo o alinhamento
          child: Icon(Icons.delete, color: Colors.white,), // L16 - add icone lixeira
        ),
      ),
      direction: DismissDirection.startToEnd, //L17 - direção para arrastar (esq para dir)
      child: CheckboxListTile( //L11 - criando cada linha da lista com um checkbox - L18 - colocando dentro do dismissable
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar( //L12 - add circle avatar para ok or not ok
          child: Icon(_toDoList[index]["ok"] ?
          Icons.check : Icons.error
          ),
        ),
        onChanged: (c) { //L13 - chamado ao clicar no seletor
          setState(() {
            _toDoList[index]["ok"] = c; //L14 - muda o state ao clicar no seletor, passando true/falso para o ["ok"] do map
            _saveData();
          });
        },
      ),
      onDismissed: (direction) { //L18 - usando a direção setada em L17
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]); //L19 pegando a posição removida e jogando em _lastRemoved
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar( //L20 - criando snackbar
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida! "),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 4),
          );
          Scaffold.of(context).removeCurrentSnackBar(); //remove a snackbar anterior
          Scaffold.of(context).showSnackBar(snack); //mostra a snackbar do item removido
        });
      }, //L15 - função ao remover item
    );
  }

  Future<File> _getFile() async { //6 - criando o Future<File>                    // - lendo o caminho do arquivo
    final directory = await getApplicationDocumentsDirectory(); //7 - retorna o diretório (await aguarda o retorno)
    return File("${directory.path}/data.json"); //8 - retorna o caminho do arquivo
  }

  Future<File> _saveData() async { // - salvando o arquivo

    String data = json.encode(_toDoList); //9 - convertendo a lista em um json e armazenando numa String
    final file = await _getFile(); //10 - pega o arquivo
    return file.writeAsString(data); //11 - escrendo a lista dentro do arquivo
  }

  Future<String> _readData() async { //12 - lendo o arquivo
    try {
      final file = await _getFile();
      return file.readAsString(); //13 - retorna arquivo lido

    } catch (e) {
      return null;
    }
  }
}
