/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |21/08/2025| Chamado 48915. Desenvolvimento da rotina de monitoramento das integrações de notas fiscais e 
              |          | exportação dos dados das integração de notas fiscais em CSV.
Julio Paz     |23/09/2025| Chamado 51973. Recompilar este fonte para atualização do ambiente de produção.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT058
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/05/2024
Descrição---------: Permite Visualizar Integração de Notas Fiscais Rejeitadas e Aceitas no Envio de Dados para a Evomilk.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT058

Local _aCores := {}
Private cCadastro 

Private aRotina := {}

aAdd(aRotina,{"Pesquisar"                                             ,"AxPesqui"       ,0,1})
aAdd(aRotina,{"Visualizar"                                            ,"AxVisual"       ,0,2})
aAdd(aRotina,{"Notas Fiscais Aceitos"                  ,"U_AGLT058Y('A')",0,2})
aAdd(aRotina,{"Notas Fiscais Rejeitadas"               ,"U_AGLT058Y('R')",0,2})
aAdd(aRotina,{"Gera Arquivo Texto Notas Fiscais Rejeitadas nas Integrações" ,'U_MGLT32OM("H")',0,2})
aAdd(aRotina,{"Gera Arquivo Texto Notas Fiscais Aceitas nas Integrações"    ,'U_MGLT32OM("I")',0,2})
aAdd(aRotina,{"Legenda"                                               ,"U_AGLT058L() "       ,0,2})

aAdd(_aCores,{"ZBV_STATUS == 'A'" ,"BR_AZUL" })
aAdd(_aCores,{"ZBV_STATUS == 'R'" ,"BR_VERMELHO" })
aAdd(_aCores,{"ZBV_STATUS == ' ' .And. (ZBV_STATNF == ' ' .Or. ZBV_STATNF == 'N') " ,"BR_AMARELO" })

DBSelectArea("ZBV")
ZBV->(DBSetOrder(1)) 
ZBV->(DBGoTop())

cCadastro := "Integração de Notas Fiscais para o App Evomilk"   

MBrowse(6,1,22,75,"ZBV", , , , , , _aCores)

Return

/*
===============================================================================================================================
Programa----------: AGLT058Y
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar os dados das Notas Fiscais Rejeitadas no Envio de Dados para a Evomilk
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT058Y(_cTipoDado)

Private aRotina := {}
Private cCadastro 
Private _aCampos := {}

If _cTipoDado == "R"
   ZBV->(DbSetFilter( { || ZBV_STATUS == "R" }, 'ZBV_STATUS == "R"' ) )
   cCadastro := "Dados das Notas Fiscais Rejeitados no Envio de Dados para o Sistema Evomilk"
Else
   ZBV->(DbSetFilter( { || ZBV_STATUS == "A" }, 'ZBV_STATUS == "A"' ) )
   cCadastro := "Dados das Notas Fiscais Aceitos no Envio de Dados para o Sistema Evomilk"
EndIf 

_aCampos := {}
aAdd(_aCampos,"ZBV_NRNFE")
aAdd(_aCampos,"ZBV_SERNFE")
aAdd(_aCampos,"ZBV_CHVNFE")
aAdd(_aCampos,"ZBV_DTEMIS")
aAdd(_aCampos,"ZBV_CODPRO")
aAdd(_aCampos,"ZBV_LOJPRO")
aAdd(_aCampos,"ZBV_NOMPRO")
aAdd(_aCampos,"ZBV_PDFNFE")
aAdd(_aCampos,"ZBV_RETNFE")
aAdd(_aCampos,"ZBV_JSONNF")
aAdd(_aCampos,"ZBV_DTENVN")
aAdd(_aCampos,"ZBV_HRENVN")
aAdd(_aCampos,"ZBV_STATNF")
aAdd(_aCampos,"ZBV_DTENVE")
aAdd(_aCampos,"ZBV_HRENVE")
aAdd(_aCampos,"ZBV_AMREFE")
aAdd(_aCampos,"ZBV_STATUS")

ZBV->(DBGoTop())

aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1,0})
aAdd(aRotina,{"Visualizar"                     ,"AxVisual"   ,0,2,0})

DBSelectArea("ZBV")
ZBV->(DBSetOrder(1)) 
ZBV->(DBGoTop())
   
MBrowse(6,1,22,75,"ZBV")

ZBV->(DBClearFilter())

Return    

/*
=================================================================================================================================
Programa--------: AGLT058W()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 18/04/2024
Descrição-------: Tela de Visualização dos dados de Integração Webservice Protheus x App Evomilk.
Parametros------: _cTab    = Alias da Tabela para Visualização dos Dados.
                  _aCampos = Campos que serão visualizados.
                  _cTitulo = Titulo da tela para a rotina que chamou a tela de visualização de dados.
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AGLT058W(_cTab, _aCampos, _cTitulo)

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
Programa----------: AGLT058L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/05/2024
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT058L

Local _aLegenda := {}

Private cCadastro

cCadastro := "Status das Integrações de Notas Fiscais "

aAdd(_aLegenda,{"BR_AZUL"    ,"Integrados com Sucesso!" })
aAdd(_aLegenda,{"BR_VERMELHO","Rejeitados!" })
aAdd(_aLegenda,{"BR_AMARELO" ,"Aguardando Integração!" })
   
BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return

/*
=================================================================================================================================
Programa--------: AGLT058V
Autor-----------: Julio de Paula Paz
Data da Criacao-: 08/05/2024
Descrição-------: Exibe os dados das integrações das notas fiscais via WebService.
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AGLT058V

Local _aStrucZBN
Local _aCmpZBN := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInvZBN := .F.
Local _oDlgEnch, _nI
Local _nReg := 2 , _nOpcx := 2

Private _oMarkZBN, _cMarcaZBN := GetMark() 
Private aHeader := {} , aCols := {}

//Montagem do aheader                                                        
aHeader := {}
FillGetDados(1,"ZBN",1,,,{||.T.},,,,,,.T.)

//                          1                    2               3              4               5                6             7        8              9                 10 
// aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})

// Cria as estruturas das tabelas temporárias
_aStrucZBN := {}
//aAdd(_aStrucZBN,{"WKRECNO", "N", 10,0})
For _nI := 1 To Len(aHeader)
      If AllTrim(aHeader[_nI,2])=="ZBN_FILIAL"
         Loop
      EndIf
      
      //                     Campo                 Titulo           Picture
      aAdd( _aCmpZBN , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )
      
      aAdd(_aStrucZBN,{aHeader[_nI,2], aHeader[_nI,8], aHeader[_nI,4] ,aHeader[_nI,5]})
Next _nI

// Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
If Select("TRBZBN") > 0
   TRBZBN->( DBCloseArea() )
EndIf

// Abre o arquivo TRBZBN criado dentro do protheus.
_otemp := FWTemporaryTable():New( "TRBZBN",  _aStrucZBN )

// Cria os indices para o arquivo.
_otemp:AddIndex( "01", {"ZBN_ITEM"} )
_otemp:Create()   
                                                                              
// Carrega os dados da tabela ZBM
For _nI := 1 To ZBM->(FCount())
      &("M->"+ZBM->(FieldName(_nI))) :=  &("ZBM->"+ZBM->(FieldName(_nI)))
Next _nI

// Carrega os dados da tabela ZBN
ZBN->(DBSetOrder(5))  // ZBN_FILIAL+ZBN_CHVNFE+ZBN_STATNF+DToS(ZBN_DTENVN)
ZBN->(DBSeek(ZBM->(ZBM_FILIAL+ZBM_CHVNFE)))
While ! ZBN->(Eof()) .And. ZBN->(ZBN_FILIAL+ZBN_CHVNFE) == ZBM->(ZBM_FILIAL+ZBM_CHVNFE)
   If ZBN->ZBN_REGCAP <> ZBM->ZBM_REGCAP
      ZBN->(DBSkip())
      Loop
   EndIf
   
   TRBZBN->(RecLock("TRBZBN",.T.))
   For _nI := 1 To TRBZBN->(FCount())
         If AllTrim(TRBZBN->(FieldName(_nI))) == "ZBN_ALI_WT" 
            TRBZBN->ZBN_ALI_WT := "ZBN" 
         ElseIf AllTrim(TRBZBN->(FieldName(_nI))) == "ZBN_REC_WT"
            TRBZBN->ZBN_REC_WT := ZBN->(Recno())
         Else
            &("TRBZBN->"+TRBZBN->(FieldName(_nI))) :=  &("ZBN->"+TRBZBN->(FieldName(_nI)))
         EndIf
   Next _nI
   TRBZBN->(MSUnLock())
   
   ZBN->(DBSkip())
EndDo
TRBZBN->(DBGoTop())
                                    
// Monta a tela Enchoice ZBM  x MsSelect ZBN
_aObjects := {} 
aAdd( _aObjects, { 315,  50, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )

_aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

_aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 

_bOk := {|| _oDlgEnch:End()}
_bCancel := {|| _lRet := .F., _oDlgEnch:End()}
                     
_cTitulo := "Integração de Notas Fiscais Via WebService para a Evomilk - Visualização"

Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel 
   
   EnChoice( "ZBM" ,_nReg, _nOpcx, , , , , _aPosObj[1], , 3 )
         
   _oMarkZBN := MsSelect():New("TRBZBN","","",_aCmpZBN,@_lInvZBN, @_cMarcaZBN,{_aPosObj[2,1], _aPosObj[2,2], _aPosObj[2,3], _aPosObj[2,4]})      
      
Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel) 


If Select("TRBZBN") > 0
   TRBZBN->(DBCloseArea())
EndIf

Return
