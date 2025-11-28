/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |26/12/2024| Chamado 49101. Realização de ajustes nos filtros de dados e na instrução Count utilizando a função MPSysOpenQuery().
Julio Paz     |21/08/2025| Chamado 48915. Ajustes na rotina para chamar funções do Cia do Leite quando usuário estiver na 
              |          | integrção Cia do Leite e da Evomilk quando o usuário estiver na integração Evomilk.
Julio Paz     |23/09/2025| Chamado 51973. Recompilar este fonte para atualização do ambiente de produção.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGLT057V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar Coletas Rejeitadas e Aceitas no Envio de Dados para a Cia do Leite e Evomilk.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT057

Local _aCores := {}
Local _nI As Numeric
Local _aParAux:= {}
Local _aParRet:= {}
Local _aOpcoes:= {}

Private aRotina := {}

Begin Sequence 

   aAdd( _aOpcoes , "1.Integrações Evomilk")
   aAdd( _aOpcoes , "2.Integrações Cia do Leite")
   aAdd( _aOpcoes , "3.Sem Filtro") 
 
   MV_PAR01 := 1 

   aAdd( _aParAux , { 3 , "Filtrar", MV_PAR01, _aOpcoes, 99, "", .T., .T. , .T. } )

   For _nI := 1 To Len( _aParAux )
       aAdd( _aParRet , _aParAux[_nI][03] )
   Next _nI 
 
   _cFiltro := NIL
   If ! ParamBox( _aParAux , "Filtros" , @_aParRet,,, .T. , , , , , .T. , .T. )
      Break
   EndIf
   
   _cFiltroSQL := ""

   aAdd(aRotina,{"Pesquisar"                                             ,"AxPesqui"       ,0,1})
   aAdd(aRotina,{"Visualizar"                                            ,"AxVisual"       ,0,2})
   aAdd(aRotina,{"Coletas Aceitas"                                       ,"U_AGLT057Y('A')",0,2})
   aAdd(aRotina,{"Coletas Rejeitadas"                                    ,"U_AGLT057Y('R')",0,2})

   If MV_PAR01 <> 3
      If MV_PAR01 = 1 
         _cFiltro:=" ZBI_WEBINT = 'E' "
         _cFiltroSQL:=" AND ZBI_WEBINT = 'E' "
         cCadastro := "Coletas Integradas para o Sistema Evomilk"   
         aAdd(aRotina,{"Gera Arquivo Texto Coletas Rejeitadas nas Integrações" ,'U_MGLT32OM("F")',0,2})
         aAdd(aRotina,{"Gera Arquivo Texto Coletas Aceitas nas Integrações"    ,'U_MGLT32OM("G")',0,2}) 
      Else
         _cFiltro:=" ZBI_WEBINT <> 'E' "
         _cFiltroSQL:=" AND ZBI_WEBINT <> 'E' "
         cCadastro := "Coletas Integradas para o Sistema Cia do Leite"   
         aAdd(aRotina,{"Gera Arquivo Texto Coletas Rejeitadas nas Integrações" ,'U_MGLT29OM("F")',0,2})
         aAdd(aRotina,{"Gera Arquivo Texto Coletas Aceitas nas Integrações"    ,'U_MGLT29OM("G")',0,2}) 
      EndIf
   Else 
      cCadastro := "Coletas Integradas para os Apps Cia do Leite e Evomilk - Sem Filtro" 
      aAdd(aRotina,{"Gera Arquivo Texto Coletas Rejeitadas nas Integrações" ,'U_MGLT29OM("F")',0,2})
      aAdd(aRotina,{"Gera Arquivo Texto Coletas Aceitas nas Integrações"    ,'U_MGLT29OM("G")',0,2})  
   EndIf
   
   aAdd(_aCores,{"ZBI_STATUS == 'A'" ,"BR_AZUL" })
   aAdd(_aCores,{"ZBI_STATUS == 'R'" ,"BR_VERMELHO" })

   DBSelectArea("ZBI")
   ZBI->(DBSetOrder(1)) 
   ZBI->(DBGoTop())

   If MV_PAR01 <> 3
      FWMsgRun(,{||  mBrowse(6,1,22,75,"ZBI",,,,,,_aCores,,,,,,,,_cFiltro) },'Aguarde Filtrando...',cCadastro)
   Else
      MBrowse(6,1,22,75,"ZBI", , , , , , _aCores)
   EndIf 

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: AGLT057Y
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar os dados das Coletas Rejeitadas no Envio de Dados para a Cia do Leite.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT057Y(_cTipoDado)

Private aRotina := {}
Private cCadastro 
Private _aCampos := {}
   
If _cTipoDado == "R"
   ZBI->(DbSetFilter( { || ZBI_STATUS == "R" }, 'ZBI_STATUS == "R"' ) )
   cCadastro := "Dados das Coletas Rejeitadas no Envio de Dados para o Sistema Cia do Leite"
Else
   ZBI->(DbSetFilter( { || ZBI_STATUS == "A" }, 'ZBI_STATUS == "A"' ) )
   cCadastro := "Dados das Coletas Aceitas no Envio de Dados para o Sistema Cia do Leite"
EndIf 

_aCampos := {}
aAdd(_aCampos,"ZBI_TICKET")
aAdd(_aCampos,"ZBI_DTCOLE")
aAdd(_aCampos,"ZBI_CODPRO")
aAdd(_aCampos,"ZBI_LOJPRO")
aAdd(_aCampos,"ZBI_NOMPRO")
aAdd(_aCampos,"ZBI_MOTIVO") 
aAdd(_aCampos,"ZBI_DTREJ")
aAdd(_aCampos,"ZBI_HRREJ") 
aAdd(_aCampos,"ZBI_JSONEN")
aAdd(_aCampos,"ZBI_DTENV")
aAdd(_aCampos,"ZBI_HRENV")
aAdd(_aCampos,"ZBI_STATUS")

ZBI->(DBGoTop())

aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1,0})
aAdd(aRotina,{"Visualizar"                     ,"U_AGLT057W('ZBI', _aCampos, cCadastro)" ,0,2,0})

DBSelectArea("ZBI")
ZBI->(DBSetOrder(1)) 
ZBI->(DBGoTop())
   
MBrowse(6,1,22,75,"ZBI")

ZBI->(DBClearFilter())

Return    

/*
=================================================================================================================================
Programa--------: AGLT057W()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 18/04/2024
Descrição-------: Tela de Visualização dos dados de Integração Webservice Protheus x App Cia do Leite.
Parametros------: _cTab    = Alias da Tabela para Visualização dos Dados.
                  _aCampos = Campos que serão visualizados.
                  _cTitulo = Titulo da tela para a rotina que chamou a tela de visualização de dados.
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AGLT057W(_cTab, _aCampos, _cTitulo)

Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel 
Local _oDlgEnch, _nI
Local _nReg := 2 , _nOpcx := 2

Private aHeader := {} , aCols := {}

Begin Sequence
  
   // Carrega os dados da tabela para visulização de dados.
   For _nI := 1 To Len(_aCampos)
       &("M->" + _aCampos[_nI]) :=  &(_cTab + "->" +_aCampos[_nI])
   Next
 
   //================================================================================
   // Monta a tela Enchoice 
   //================================================================================    
   _aObjects := {} 
   aAdd( _aObjects, { 315,  50, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 
   
   _bOk := {|| _oDlgEnch:End()}
   _bCancel := {|| _oDlgEnch:End()}
   
   Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel 
      
      EnChoice( _cTab ,_nReg, _nOpcx, , , ,_aCampos , _aPosObj[1], , 3 )
                        
   Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel) 

End Sequence

Return

/*
===============================================================================================================================
Programa----------: AGLT057L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 22/04/2024
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT057L

Local _aLegenda := {}

aAdd(_aLegenda,{"BR_AZUL"    ,"Integrados com Sucesso!" })
aAdd(_aLegenda,{"BR_VERMELHO","Rejeitados!" })
   
BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return
