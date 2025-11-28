/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |21/08/2025| Chamado 48915. Desenvolvimento da rotina de monitoramento das integrações de extratos/demonstrativos 
              |          | e exportação dos dados das integração de extratos/demonstrativos em CSV.
Julio Paz     |23/09/2025| Chamado 51973. Recompilar este fonte para atualização do ambiente de produção.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT060
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/05/2024
Descrição---------: Permite Visualizar Integração de Extratos de Produtores Rejeitadas e Aceitas no Envio de Dados 
                    para a Evomilk.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT060

Local _aCores := {}
Private cCadastro 

Private aRotina := {}

aAdd(aRotina,{"Pesquisar"                                             ,"AxPesqui"       ,0,1})
aAdd(aRotina,{"Visualizar"                                            ,"AxVisual"       ,0,2})
aAdd(aRotina,{"Extratos/Demonstrativos Aceitos"                  ,"U_AGLT060Y('A')",0,2})
aAdd(aRotina,{"Extratos/Demonstrativos Rejeitadas"               ,"U_AGLT060Y('R')",0,2})
aAdd(aRotina,{"Gera Arquivo Texto Extratos/Demonstrativos Rejeitadas nas Integrações" ,'U_MGLT32OM("J")',0,2})
aAdd(aRotina,{"Gera Arquivo Texto Extratos/Demonstrativos Aceitas nas Integrações"    ,'U_MGLT32OM("K")',0,2})
aAdd(aRotina,{"Legenda"                                               ,"U_AGLT060L() "       ,0,2})

aAdd(_aCores,{"ZBX_STATUS == 'A'" ,"BR_AZUL" })
aAdd(_aCores,{"ZBX_STATUS == 'R'" ,"BR_VERMELHO" })
aAdd(_aCores,{"ZBX_STATUS == ' ' .And. (ZBX_STATNF == ' ' .Or. ZBX_STATNF == 'N') " ,"BR_AMARELO" })

DBSelectArea("ZBX")
ZBX->(DBSetOrder(1)) 
ZBX->(DBGoTop())

cCadastro := "Integração de Extratos/Demonstrativos para o App Evomilk"   

MBrowse(6,1,22,75,"ZBX", , , , , , _aCores)

Return

/*
===============================================================================================================================
Programa----------: AGLT060Y
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar os dados das Extratos/Demonstrativos Rejeitadas no Envio de Dados para a Evomilk.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT060Y(_cTipoDado)

Private aRotina := {}
Private cCadastro 
Private _aCampos := {}

If _cTipoDado == "R"
   ZBX->(DbSetFilter( { || ZBX_STATUS == "R" }, 'ZBX_STATUS == "R"' ) )
   cCadastro := "Dados das Extratos/Demonstrativos Rejeitados no Envio de Dados para o Sistema Evomilk"
Else
   ZBX->(DbSetFilter( { || ZBX_STATUS == "A" }, 'ZBX_STATUS == "A"' ) )
   cCadastro := "Dados das Extratos/Demonstrativos Aceitos no Envio de Dados para o Sistema Evomilk"
EndIf 

_aCampos := {}
aAdd(_aCampos,"ZBX_NRNFE")
aAdd(_aCampos,"ZBX_SERNFE")
aAdd(_aCampos,"ZBX_DTEMIS")
aAdd(_aCampos,"ZBX_CODPRO")
aAdd(_aCampos,"ZBX_LOJPRO")
aAdd(_aCampos,"ZBX_NOMPRO")
aAdd(_aCampos,"ZBX_PDFEXT")
aAdd(_aCampos,"ZBX_RETEXT")
aAdd(_aCampos,"ZBX_JSONEX")
aAdd(_aCampos,"ZBX_DTENVE")
aAdd(_aCampos,"ZBX_HRENVE")
aAdd(_aCampos,"ZBX_AMREFE")
aAdd(_aCampos,"ZBX_DTHORA")
aAdd(_aCampos,"ZBX_OBSERV")
aAdd(_aCampos,"ZBX_STATUS")

ZBX->(DBGoTop())

aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1,0})
aAdd(aRotina,{"Visualizar"                     ,"AxVisual"   ,0,2,0})

DBSelectArea("ZBX")
ZBX->(DBSetOrder(1)) 
ZBX->(DBGoTop())
   
MBrowse(6,1,22,75,"ZBX")

ZBX->(DBClearFilter())

Return    

/*
=================================================================================================================================
Programa--------: AGLT060W()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 18/04/2024
Descrição-------: Tela de Visualização dos dados de Integração Webservice Protheus x App Evomilk.
Parametros------: _cTab    = Alias da Tabela para Visualização dos Dados.
                  _aCampos = Campos que serão visualizados.
                  _cTitulo = Titulo da tela para a rotina que chamou a tela de visualização de dados.
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AGLT060W(_cTab, _aCampos, _cTitulo)

Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel 
Local _oDlgEnch, _nI
Local _nReg := 2 , _nOpcx := 2

Private aHeader := {} , aCols := {}
  
// Carrega os dados da tabela para visulização de dados.
For _nI := 1 To Len(_aCampos)
      &("M->" + _aCampos[_nI]) :=  &(_cTab + "->" +_aCampos[_nI])
Next _nI

// Monta a tela Enchoice 
_aObjects := {} 
aAdd( _aObjects, { 315,  50, .T., .T. } )

_aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

_aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 

_bOk := {|| _oDlgEnch:End()}
_bCancel := {|| _oDlgEnch:End()}

Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel 
   
   EnChoice( _cTab ,_nReg, _nOpcx, , , ,_aCampos , _aPosObj[1], , 3 )
                     
Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel)

Return

/*
===============================================================================================================================
Programa----------: AGLT060L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/05/2024
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT060L

Local _aLegenda := {}

Private cCadastro

cCadastro := "Status das Integrações de Extratos/Demostrativos"

aAdd(_aLegenda,{"BR_AZUL"    ,"Integrados com Sucesso!" })
aAdd(_aLegenda,{"BR_VERMELHO","Rejeitados!" })
aAdd(_aLegenda,{"BR_AMARELO" ,"Aguardando Integração!" })
   
BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return
   
