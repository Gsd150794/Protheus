/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |22/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIN010
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Rotina para possibilitar a alteração do Vencimento/Historico/Carteria CR de varios titulos do contas a 
                    receber de uma unica vez ou de um ou mais informados pelo usuario.	
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN010
                             
Local 	_lAcesso 	:= .F. As Logical
Private _cPerg		:= "MFIN010B" As Character
Private _aItalac_F3 := {} As Array//usado no F3 dos MV_PAR01 e MV_PAR13
Private aHeader     := {} As Array//MSGETDB
Private _cColunas   := "" As Character

// verifica se pode executar a rotina
_lAcesso := U_ITVACESS( 'ZZL' , 3 , 'ZZL_CRMULT' , "S" )

If !_lAcesso
	FWAlertWarning('Usuário sem acesso à rotina de manutenção de vencimentos de contas a receber! '+;
			'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.','MFIN01001')
	Return
EndIf

While .T.
   If !Pergunte(_cPerg,.T.)   
      Return
   EndIf  
   
   If MFIN010SE()
      Loop
   EndIf
EndDo

Return

/*
===============================================================================================================================
Programa----------: MFIN010SE
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Processamento leitura e montagem do browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN010SE

Local _oPanel 	:= Nil As Object
Local _oDlg1 	:= Nil As Object
Local _aSize    := {} As Array
Local _aBotoes  := {} As Array
Local aAlter	:= {"E1_VENCREA","E1_HIST","E1_I_CART"} As Array

Private _oQtda		:= Nil As Object
Private nOpca		:= 0 As Numeric
Private _nQtdTit	:= 0 As Numeric
Private _nTotTit	:= 0 As Numeric
Private aObjects	:= {} As Array
Private aPosObj1	:= {} As Array
Private aInfo		:= {} As Array
Private _cAlias		:= "" As Character
Private aTitulo		:= {} As Array
Private aStruct		:= {} As Array
Private cArqTRB1	:= "" As Character
Private _lLoop		:= .F. As Logical
Private oBrowse		:= Nil As Object
Private aRotina		:= { {"Pesquisar","AxPesqui"    ,0,1} } As Array//aRotina usada na msgetdb()
aAdd(aRotina, {"Alterar","U_Altera"   ,0,4} )
                                                                                 
Begin Transaction

Begin Sequence

// Insere os dados no arquivo temporario criado                    
FWMsgRun( ,{|oProc| _lLoop:=MFIN010XP(@_cAlias,oProc) } ,'Aguarde!','Lendo os dados...'  )

If _lLoop
   Break
EndIf

// Faz o calculo automatico de dimensoes de objetos     
_aSize := MSADVSIZE()                    
// Obtem tamanhos das telas                                            
aAdd( aObjects, { 0, 0, .T., .T., .T. } )
aInfo    := { _aSize[ 1 ], _aSize[ 2 ], _aSize[ 3 ], _aSize[ 4 ], 3, 3 } 
aPosObj1 := MsObjSize( aInfo, aObjects,  , .T. ) 

aAdd( _aBotoes, {"" ,{|| MFIN010VT()         },"","Visualizar Titulo"})
aAdd( _aBotoes, {"" ,{|| MFIN010OR(_cAlias,1)},"","Inverte Marcação"})
aAdd( _aBotoes, {"" ,{|| MFIN010OR(_cAlias,2)},"","Des/Marca Todos"})
aAdd( _aBotoes, {"" ,{|| MFIN010OR(_cAlias,3)},"","Altera Marcados"})

// Cria a tela para selecao dos Titulos                              
DEFINE MSDIALOG _oDlg1 TITLE "ROTINA DE ALTERAÇÃO DE DADOS DOS TÍTULOS A RECEBER" From 0,0 To _aSize[6],_aSize[5] PIXEL

	_oPanel := TPanel():New(0,0,'',_oDlg1,, .T., .T.,, ,315,30,.T.,.T. )

	@ 0.8 ,00.8 Say OemToAnsi("Quantidade:")  OF _oPanel 
	@ 0.8 ,0005 Say _oQtda VAR _nQtdTit Picture "@E 999999" SIZE 60,8 OF _oPanel 

	@ 0.8 ,0020 Say OemToAnsi("Valor:") OF _oPanel 
	@ 0.8 ,0025 Say _oTotd VAR _nTotTit Picture "@E 999,999,999.00" SIZE 60,8 OF _oPanel 

	// Legenda    
	@ 0.0 ,037.5 Say OemToAnsi("Legenda:") OF _oPanel         

	@ 0.8 ,039   Say OemToAnsi("- Título em aberto (Não sofreu baixa) ")        OF _oPanel 
	@ 010, 300 BITMAP oBitmap1 SIZE 022, 016 OF _oPanel FILENAME 'br_verde' NOBORDER PIXEL

	@ 1.4 ,039  Say OemToAnsi("- Baixado parcialmente ")        OF _oPanel 
	@ 018, 300 BITMAP oBitmap1 SIZE 022, 016 OF _oPanel FILENAME 'br_azul'  NOBORDER PIXEL

	DBSelectArea(_cAlias)
	(_cAlias)->(DBSetOrder(0))
	(_cAlias)->(DBGoTop())
//               MsGetDb():New(nT   ,nL ,nB           ,nR     ,nOpcX,cLinhaOk,cTudoOk,cIniCpos,lDeleta,aAlter,nFreeze,lEmpty,nMax,cTrb   ,cFieldOk,lCondicional,lAppend,oWnd  ,lDisparos,lIndex,cDelOk,cSuperDel)
	oBrowse:=MsGetDb():New(35,01,_aSize[6]-10,_aSize[5]-10,2    ,        ,       ,        ,.F.    ,aAlter,       ,      ,    ,_cAlias,        ,            ,.F.    ,_oDlg1,         ,      ,      ,         )
	b2Click:=oBrowse:oBrowse:bLDblClick
	oBrowse:oBrowse:bLDblClick := { || MFIN010ST(_cAlias , (_cAlias)->STATUS) }
	oBrowse:oBrowse:bAdd := {||.F.} // não inclui novos itens MsGetDb()

ACTIVATE MSDIALOG _oDlg1 ON INIT (EnchoiceBar(_oDlg1, {|| If(U_MFIN10Val("OK") ,;
                                                             Eval({|| nOpca := 1,_oDlg1:End() }),) },;
                                                             {|| nOpca := 2,_oDlg1:End()},,_aBotoes),;
                                   _oPanel:Align := CONTROL_ALIGN_TOP,;
                                   oBrowse:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT,oBrowse:oBrowse:Refresh() )

If nOpca = 1 
   FWMsgRun( ,{|oProc| MFIN010AV(_cAlias,oProc) } ,'Aguarde!','Gravando os dados...'  )
   _lLoop:=.T.
Else
   _lLoop:=.F.
EndIf

End Sequence
// Efetuando o desbloqueio dos titulos anteriormente bloqueados no momento de sua selecao         
MsgRun("AGUARDE, EFETUANDO O DESBLOQUEIO DOS TITULOS!!!.",,{|| MFIN010DT() })

End Transaction
//===============================================================
// Fecha a area de uso do arquivo temporario no Protheus.          
// Apaga o arquivo e o indice fisicamente no diretorio definido pelo "\StartPath\". 
//===============================================================
(_cAlias)->(DBCloseArea())
Ferase(cArqTRB1+OrdBagExt()) 

Return _lLoop

/*
===============================================================================================================================
Programa----------: MFIN010CR
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Cria tabela temporaria para montagem da tela 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN010CR(cTab As Character)

Local I := 0 As Numeric
Local aSemSX3 := {} As Array
Local aStruct := {} As Array

aTitulo  := {}
cTab:="E1"
//===============================================================
// Criando estrutura da tabela temporaria das unidades                 
//===============================================================
aAdd(aSemSX3,{"STATUS"   ,"C",04,1})  // Coluna do aHeader 01
aAdd(aSemSX3,{"LEGEND"   ,"C",08,1})  // Coluna do aHeader 02
aAdd(aSemSX3,{"E1_FILIAL","C",02,0})  // Coluna do aHeader 03 // Campo não usado: não cria automatico no E_CriaTrab() e tem que por manual no aHeader
aAdd(aSemSX3,{"SE1REC"   ,"N",15,0})  // não entra do aHerader
//aAdd(aSemSX3,{"E1_SALDO","N",18,2}) // Campo não usado: não cria automatico no E_CriaTrab() e tem que por manual no aHeader

aAdd(aStruct,{"E1_PREFIXO"})// ,"C",03,1,1   })// Coluna do aHeader 04
aAdd(aStruct,{"E1_NUM"    })// ,"C",09,1,1   })// Coluna do aHeader 05
aAdd(aStruct,{"E1_PARCELA"})// ,"C",02,1,1   })// Coluna do aHeader 06
aAdd(aStruct,{"E1_TIPO"   })// ,"C",03,1,1   })// Coluna do aHeader 07
aAdd(aStruct,{"E1_VENCREA"})// ,"D",08,1,1   })// Coluna do aHeader 08 CAMPO EDITAVEL
_cColunas+=AllTrim(Str(Len(aStruct)+3))+","
aAdd(aStruct,{"E1_HIST"   })// ,"C",20,1,0   })// Coluna do aHeader 09 CAMPO EDITAVEL
_cColunas+=AllTrim(Str(Len(aStruct)+3))+","
aAdd(aStruct,{"E1_I_CART" })// ,"C",20,1,0   })// Coluna do aHeader 10 CAMPO EDITAVEL
_cColunas+=AllTrim(Str(Len(aStruct)+3))
aAdd(aStruct,{"E1_NATUREZ"})// ,"C",10,1,0   })// Coluna do aHeader 11
aAdd(aStruct,{"E1_CLIENTE"})// ,"C",06,1,0   })// Coluna do aHeader 12
aAdd(aStruct,{"E1_LOJA"   })// ,"C",04,1,0   })// Coluna do aHeader 13
aAdd(aStruct,{"E1_NOMCLI" })// ,"C",20,1,1   })// Coluna do aHeader 14
aAdd(aStruct,{"E1_EMISSAO"})// ,"D",08,1,0   })// Coluna do aHeader 15
aAdd(aStruct,{"E1_VENCTO" })// ,"D",08,1,1   })// Coluna do aHeader 16
aAdd(aStruct,{"E1_VALOR"  })// ,"N",17,2,0   })// Coluna do aHeader 17
//aAdd(aStruct,{"E1_NUMBOR" })

aCampos:={}
For I := 1 TO Len(aStruct)
    aAdd(aCampos, aStruct[I,1] )//Le os dados do SX3 dentro da função E_CriaTrab
Next
aHeader:={}//        1           2           3                      4                    5                 6               7       8       9         10
//aAdd(aHeader,{X3Titulo() ,x3_Campo    ,x3_picture           ,x3_tamanho           ,x3_decimal          ,x3_valid    ,x3_usado,x3_tipo,x3_arquivo,x3_context}))
aAdd(aHeader  ,{""         ,"STATUS"   ,"@BMP"               ,4                    ,0                   ,""          ,""      ,""     ,""        ,"" })
aAdd(aHeader  ,{""         ,"LEGEND"   ,"@BMP"               ,4                    ,0                   ,""          ,""      ,""     ,""        ,"" })
aAdd(aHeader  ,{"Filial"   ,"E1_FILIAL","@!"                 ,2                    ,0                   ,""          ,""      ,"C"    ,"SE1"     ,"R"})

cTab:=CriaTrab(Nil,.F.)
cArqTRB1:=E_CriaTrab(,aSemSX3,cTab,,)//Cria o Temporario e abre, e preenche a aHeader baseados nos campos do SX3 do aCampos

For I := 1 TO Len(aHeader)
   If aHeader[I,2] = "E1_VENCREA"
      aHeader[I,6]:= "U_MFIN10Val('DATA',M->E1_VENCREA)"
  Else
      aHeader[I,6]:=".T."//Regravava o valid padrão do SX3
  EndIf    
Next

// Cria os indices para o arquivo.                                 
Private cIndTRB1  := "E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA"  

IndRegua(cTab,cArqTRB1,cIndTRB1)
                                                                        
// Agrega um arquivo de indice a um Alias ativo no sistema.        
DBSelectArea(cTab)                  
DBSETINDEX(cArqTRB1)

Return
      
/*
===============================================================================================================================
Programa----------: MFIN010XP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Insere os dados selecionados de acordo com os filtros informados pelo usuario no arquivo temporario criado
Parametros--------: ctab - Alias dos dados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN010XP(cTab As Character,oProc As Object)
                 
Local _cAliasSE1:= GetNextAlias() As Character
Local _cFiltro  := "" As Character
Local nConta	:=0 As Numeric

oProc:cCaption := "Criando estrutura e Filtrando Titulos..."
ProcessMessages()

MFIN010CR(@cTab)

//================      
// Filtros
//================

//=========================================		
// Natureza do Titulo
//=========================================
If !Empty(MV_PAR01)
	_cFiltro  += " AND E1.E1_NATUREZ IN " + FormatIn(MV_PAR01,";")
EndIf      

//=========================================
// Filial
//=========================================
_cFiltro += IIf( !Empty( MV_PAR02 ) , " AND E1.E1_FILIAL IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" )

//=========================================		      	
// Emissao de - Ate
//=========================================
If !Empty(MV_PAR03) .And. !Empty(MV_PAR04)	
	_cFiltro += " AND E1.E1_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "'"
EndIf     

//=========================================		
// Vencimento Real De - Ate
//=========================================
If !Empty(MV_PAR05) .And. !Empty(MV_PAR06)	
	_cFiltro  += " AND E1.E1_VENCREA BETWEEN '" + DToS(MV_PAR05) + "' AND '" + DToS(MV_PAR06) + "'"
EndIf   

//=========================================
// Vencimento original De - Ate
//=========================================
If !Empty(MV_PAR07) .And. !Empty(MV_PAR08)	
	_cFiltro  += " AND E1.E1_VENCTO BETWEEN '" + DToS(MV_PAR07) + "' AND '" + DToS(MV_PAR08) + "'"
EndIf   

//=========================================		
// Cliente De - Ate 
//=========================================
If !Empty(MV_PAR09) .And. !Empty(MV_PAR11)	
	_cFiltro  += " AND E1.E1_CLIENTE BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR11 + "'"
EndIf                                                             

//=========================================		
// Loja Cliente De - Ate
//=========================================
If !Empty(MV_PAR10) .And. !Empty(MV_PAR12)	
	_cFiltro  += " AND E1.E1_LOJA BETWEEN '" + MV_PAR10 + "' AND '" + MV_PAR12 + "'"
EndIf             

//=========================================		
// Prefixo do Titulo
//=========================================
If !Empty(MV_PAR13)
	_cFiltro  += " AND E1.E1_PREFIXO IN " + FormatIn(MV_PAR13,";")
EndIf   

//=========================================		
// Tipo do Titulo    
//=========================================
If !Empty(MV_PAR14)
	_cFiltro  += " AND E1.E1_TIPO IN " + FormatIn(MV_PAR14,";")
EndIf      

//=========================================		
//No. do Titulo De - Ate
//=========================================
If !Empty(MV_PAR15) .And. !Empty(MV_PAR16)	
	_cFiltro  += " AND E1.E1_NUM BETWEEN '" + MV_PAR15 + "' AND '" + MV_PAR16 + "'"
EndIf             

//===============================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta. 
//===============================================================
If Select(_cAliasSE1) <> 0
	_cAliasSE1->(DBCloseArea())
EndIf

//===============================================================
// Query para selecao dos dados 
//===============================================================
_cQuery:=" SELECT R_E_C_N_O_ SE1REC FROM "+RetSqlName('SE1')+ " E1 "
_cQuery+="	WHERE D_E_L_E_T_ = ' ' AND E1_SALDO > 0 AND E1_TIPO <> 'RA '  "
_cQuery+= _cFiltro
_cQuery+="	ORDER BY  E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA "
_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAliasSE1)

If (_cAliasSE1)->(Eof())
	FWAlertWarning("Não foram encontrados registros para esses filtros. Selecione outros filtros.","MFIN01001")
	Return .T.
EndIf

DBSelectArea(_cAliasSE1)
COUNT TO xTotal
xTotal:=AllTrim(Str(xTotal))
(_cAliasSE1)->(DBGoTop())

SE1->(DBSetOrder(1))

While (_cAliasSE1)->(!Eof())
	
    nConta++
    oProc:cCaption := "Lendo Titulo: "+AllTrim(Str(nConta))+ " de "+xTotal
    ProcessMessages()
	SE1->(DBGoTo((_cAliasSE1)->SE1REC))
	SE1->(MSUnLock())	
	SE1->(RecLock("SE1",.F.))// Bloqueia os titulos selecionados na pesquisa, para que não seja possivel enquanto esta rotina estiver sendo utilizada a sua alteracao
	
	(cTab)->(DBAPPEND())
	AVREPLACE("SE1",cTab)

    (cTab)->STATUS := "LBNO"
    (cTab)->LEGEND := If( SE1->E1_VALOR == SE1->E1_SALDO ,'BR_VERDE','BR_AZUL' )
    (cTab)->SE1REC := (_cAliasSE1)->SE1REC
	// Se estiver vazio procura no cadastro de clientes
	If Empty(SE1->E1_NOMCLI)
		(cTab)->E1_NOMCLI := Posicione("SA1",1,xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA,"A1_NOME")
	EndIf
  			
	(_cAliasSE1)->(DBSkip())            
	
EndDo

U_ITLOGACS('MFIN010')
(_cAliasSE1)->(DBCloseArea())
DBSelectArea(cTab)

Return .F.

/*
===============================================================================================================================
Programa----------: MFIN010ST
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Marca ou desmarca no clique/espaço
Parametros--------: ctab - Alias dos dados
					_cStatus - se marca ou desmarca itens
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function MFIN010ST(cTab,_cStatus)

If AllTrim(Str(oBrowse:oBrowse:nColPos,2)) $ _cColunas//Colunas editaveis 8 , 9 , 10 
	If (cTab)->STATUS = "LBOK"
		Return EVAL(b2Click)
	EndIf
EndIf

If _cStatus = "LBNO"//_cStatus == Space(2)
	(cTab)->STATUS:= "LBOK"
	_nQtdTit++
	
	// se é títulio NCC conta negativo
	If &(cTab+'->E1_TIPO') == 'NCC'
		_nTotTit -=  &(cTab+'->E1_VALOR')
	Else
		_nTotTit +=  &(cTab+'->E1_VALOR')
	EndIf
Else
	(cTab)->STATUS:= "LBNO"
	_nQtdTit--
	// se é título NCC conta negativo
	If &(cTab+'->E1_TIPO') == 'NCC'
		_nTotTit +=  &(cTab+'->E1_VALOR')
	Else
		_nTotTit -=  &(cTab+'->E1_VALOR')
	EndIf
EndIf
	
_nQtdTit:= IIf(_nQtdTit<0,0,_nQtdTit)

_oQtda:Refresh()	
_oTotd:Refresh()
	
Return EVAL(b2Click)

/*
===============================================================================================================================
Programa----------: MFIN010OR
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Inverte produtos selecionados
Parametros--------: 	ctab - Alias dos dados
					 	nColuna - confirmação de execução
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MFIN010OR(_cAlias As Character,nBotao As Numeric)

Local _aArea	:= FWGetArea() As Array
Local _cStatus	:= If((_cAlias)->STATUS = "LBNO","LBOK","LBNO")

Private _dData	:=(_cAlias)->E1_VENCREA As Date
Private _cHist	:=(_cAlias)->E1_HIST As Character
Private _cCart	:=(_cAlias)->E1_I_CART As Character
Private _lData	:= .T. As Logical
Private _lHist	:= !Empty((_cAlias)->E1_HIST) As Logical
Private _lCart	:= !Empty((_cAlias)->E1_I_CART) As Logical
	
If nBotao = 3 .And. !MFIN10Get()//Altera Marcados
   Return .F.
EndIf

// Marca ou desmarca todos os titulos selecionados
If nBotao = 2//Des/Marca todos
   _nQtdTit:=0
   _nTotTit:=0
EndIf

(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())
	If nBotao = 2//Des/Marca todos
		(_cAlias)->STATUS = _cStatus
		If (_cAlias)->STATUS = "LBOK"
			_nQtdTit++
			If &(_cAlias+'->E1_TIPO') == 'NCC'
				_nTotTit -=  &(_cAlias+'->E1_VALOR')
			Else
				_nTotTit +=  &(_cAlias+'->E1_VALOR')
			EndIf
		EndIf
		(_cAlias)->(DBSkip())
		Loop
	EndIf

	If nBotao = 3//Altera Marcados
		If (_cAlias)->STATUS = "LBOK"
           If _lData 
              (_cAlias)->E1_VENCREA:=_dData
		   EndIf
           If _lHist 
              (_cAlias)->E1_HIST  :=_cHist
		   EndIf
           If _lCart 
              (_cAlias)->E1_I_CART:=_cCart
		   EndIf
		EndIf
		(_cAlias)->(DBSkip())
		Loop
	EndIf
	
	// Se o titulo nao estiver selecionado
	If (_cAlias)->STATUS = "LBNO" 
	   (_cAlias)->STATUS:= "LBOK"
		_nQtdTit++
		// Se é título NCC conta negativo
		If &(_cAlias+'->E1_TIPO') == 'NCC'
			_nTotTit -=  &(_cAlias+'->E1_VALOR')
		Else
			_nTotTit +=  &(_cAlias+'->E1_VALOR')
		EndIf
		// Titulo selecionado
	Else
		(_cAlias)->STATUS = "LBNO"
		_nQtdTit--
		// se é título NCC conta negativo
		If &(_cAlias+'->E1_TIPO') == 'NCC'
			_nTotTit +=  &(_cAlias+'->E1_VALOR')
		Else
			_nTotTit -=  &(_cAlias+'->E1_VALOR')
		EndIf
	EndIf
	(_cAlias)->(DBSkip())
EndDo

_nQtdTit:= IIf(_nQtdTit<0,0,_nQtdTit)
_oQtda:Refresh()
_oTotd:Refresh()

FWRestArea(_aArea)			                 
		      
(_cAlias)->(DBSetOrder(0))
(_cAlias)->(DBGoTop())
oBrowse:oBrowse:Refresh(.T.)      
      
Return                                               

/*
===============================================================================================================================
Programa----------: MFIN010VT
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Funcao para Visualizacao no arquivo temporario.
Parametros--------: 	
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MFIN010VT()

Local 	aArea		:= FWGetArea() As Array
Private cCadastro 	:= "Visualizar" As Character

DBSelectArea("SE1")
SE1->(DBSetOrder(1))
SE1->(DBGoTo( (_cAlias)->SE1REC ))

AxVisual( "SE1", SE1->( Recno() ), 2 )

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: MFIN010DT
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: desbloqueia os títulos na saída da função
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MFIN010DT

(_cAlias)->(DBGoTop())
While (_cAlias)->(!Eof())
   SE1->(DBGoTo( (_cAlias)->SE1REC ))
   SE1->(MSUnLock())
   (_cAlias)->(DBSkip())
EndDo
SE1->(MSUnLockAll())

Return .T.

/*
===============================================================================================================================
Programa----------: MFIN010AV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Altera via siga-auto a data de vencimento real do titulo.  
Parametros--------: _cAlias,oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN010AV(_cAlias As Character,oProc As Object)

Local _aArea	:= FWGetArea() As Array
Local _nModOld	:= nModulo As Numeric
Local _cModOld	:= cModulo As Character
Local _cFilOld	:= cFilant As Character
Local _aAutoSE1	:= {} As Array
Local _aLog		:= {} As Array
Local _dVenc	:= SToD("//") As Date
Local nConta	:= 0 As Numeric
Private nGravados:= 0 As Numeric

(_cAlias)->(DBGoTop())

aAdd( _aLog , "FUNÇÃO MFIN010 - ALTERAÇÃO DE DADOS DE TITULOS A RECEBER"	)	
aAdd( _aLog , "DATA DO INICIO DO PROCESSAMENTO: "+ DToC( Date() )	)
aAdd( _aLog , "HORA DO INICIO DO PROCESSAMENTO: "+ TIME())
aAdd( _aLog , "USUARIO: " + FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3] +;
		 " - " + FWSFAllUsers({__cUserID},{"USR_NOME"})[1][3])
aAdd( _aLog , "")
aAdd( _aLog , "PARÂMETROS: "	)	
aAdd( _aLog , "Naturezas........:" + AllTrim(MV_PAR01))
aAdd( _aLog , "Filiais..........:" + AllTrim(MV_PAR02))
aAdd( _aLog , "Emissao de.......:" + DToC(MV_PAR03))
aAdd( _aLog , "Emissao Ate......:" + DToC(MV_PAR04))
aAdd( _aLog , "Venc. Real de....:" + DToC(MV_PAR05))
aAdd( _aLog , "Venc. Real Ate...:" + DToC(MV_PAR06))
aAdd( _aLog , "Venc. Orig. de...:" + DToC(MV_PAR07))
aAdd( _aLog , "Venc. Orig. Ate..:" + DToC(MV_PAR08))
aAdd( _aLog , "Cliente De.......:" + AllTrim(MV_PAR09))
aAdd( _aLog , "Loja De..........:" + AllTrim(MV_PAR10))
aAdd( _aLog , "Cliente Ate......:" + AllTrim(MV_PAR11))
aAdd( _aLog , "Loja Ate.........:" + AllTrim(MV_PAR12))
aAdd( _aLog , "Prefixo Titulo...:" + AllTrim(MV_PAR13))
aAdd( _aLog , "Tipo Titulo......:" + AllTrim(MV_PAR14))
aAdd( _aLog , "No. Titulo de....:" + AllTrim(MV_PAR15))
aAdd( _aLog , "No. Titulo Ate...:" + AllTrim(MV_PAR16))
aAdd( _aLog , "")

nPulaLog:=Len(_aLog)

Count To xTotal
xTotal:=AllTrim(Str(xTotal))
(_cAlias)->(DBGoTop())

SE1->(DBSetOrder(1))

nModulo	:= 6
cModulo := "FIN"

While (_cAlias)->(!Eof())
    nConta++
    oProc:cCaption := "Lendo Titulo: "+AllTrim(Str(nConta))+ " de "+xTotal+", Gravados: "+AllTrim(Str(nGravados))
    ProcessMessages()
	
	If (_cAlias)->STATUS == "LBOK"// Somente registros marcados 
		SE1->(DBGoTo( (_cAlias)->SE1REC ))
		
		If (_cAlias)->E1_VENCREA <> SE1->E1_VENCREA .OR.; 
			(_cAlias)->E1_HIST   <> SE1->E1_HIST   .OR.;
			(_cAlias)->E1_I_CART <> SE1->E1_I_CART
		
		    SE1->(MSUnLock())
	
	        // Muda filial do ambiente e salva dados
	        cFilant := (_cAlias)->E1_FILIAL
			_dVenc 	:= SE1->E1_VENCREA
			_cHist 	:= AllTrim(SE1->E1_HIST)
			_cCar  	:= SE1->E1_I_CART
			
			_aAutoSE1:={}        
			
			aAdd( _aAutoSE1, { "E1_FILIAL"	, (_cAlias)->E1_FILIAL		, nil } )
			aAdd( _aAutoSE1, { "E1_PREFIXO"	, SE1->E1_PREFIXO			, nil } )
			aAdd( _aAutoSE1, { "E1_NUM"		, SE1->E1_NUM   			, nil } )
			aAdd( _aAutoSE1, { "E1_PARCELA"	, SE1->E1_PARCELA			, nil } )
			aAdd( _aAutoSE1, { "E1_TIPO"	, SE1->E1_TIPO				, nil } )
			aAdd( _aAutoSE1, { "E1_NATUREZ"	, SE1->E1_NATUREZ			, nil } )
			aAdd( _aAutoSE1, { "E1_CLIENTE"	, SE1->E1_CLIENTE			, nil } )
			aAdd( _aAutoSE1, { "E1_LOJA"	, SE1->E1_LOJA  			, nil } )
			aAdd( _aAutoSE1, { "E1_EMISSAO"	, SE1->E1_EMISSAO			, nil } )
			aAdd( _aAutoSE1, { "E1_VENCTO"	, SE1->E1_VENCTO			, nil } )
			aAdd( _aAutoSE1, { "E1_VENCREA"	, DataValida((_cAlias)->E1_VENCREA), nil } )
			aAdd( _aAutoSE1, { "E1_I_VCPOR"	, DataValida((_cAlias)->E1_VENCREA), nil } )
			aAdd( _aAutoSE1, { "E1_VALOR"	, SE1->E1_VALOR 			, nil } )
			aAdd( _aAutoSE1, { "E1_HIST"	, (_cAlias)->E1_HIST 		, nil } )
			aAdd( _aAutoSE1, { "E1_I_CART"	, (_cAlias)->E1_I_CART  	, nil } )
		
			lMsErroAuto := .F.    
  			MSExecAuto({|x,y,z| Fina040(x,y,z)},_aAutoSE1,4) //Alteracao
	
		    SE1->(DBGoTo( (_cAlias)->SE1REC ))
		    
			If lMsErroAuto
                _cErro:=mostraerro()
				aAdd( _aLog ,"5-Erro ao alterar o seguinte título: " + SE1->E1_FILIAL+"/"+SE1->E1_NUM +"/" + SE1->E1_PARCELA + " do Cliente: " + SE1->E1_CLIENTE + "/" + SE1->E1_LOJA+ " - " + Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NREDUZ")+" ["+_cErro+"]" )
			Else
		        If _dVenc <> SE1->E1_VENCREA
				   aAdd( _aLog ,"1-O título: " + SE1->E1_FILIAL+"/"+SE1->E1_NUM +"/" + SE1->E1_PARCELA+ " do Cliente: " + SE1->E1_CLIENTE+ "/" + SE1->E1_LOJA + " - " + Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NREDUZ") + ", teve vencimento real alterado de " + DToC(_dVenc) + " para " + DToC(SE1->E1_VENCREA) )
			    EndIf	
			    If _cHist <> SE1->E1_HIST   
				   aAdd( _aLog ,"2-O título: " + SE1->E1_FILIAL+"/"+SE1->E1_NUM +"/" + SE1->E1_PARCELA+ " do Cliente: " + SE1->E1_CLIENTE+ "/" + SE1->E1_LOJA + " - " + Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NREDUZ") + ", teve Historico alterado de "       + _cHist       + " para " + SE1->E1_HIST  )
			    EndIf	
			    If _cCar <> SE1->E1_I_CART
				   aAdd( _aLog ,"3-O título: " + SE1->E1_FILIAL+"/"+SE1->E1_NUM +"/" + SE1->E1_PARCELA+ " do Cliente: " + SE1->E1_CLIENTE+ "/" + SE1->E1_LOJA + " - " + Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NREDUZ") + ", teve carteira cr alterado de "     + _cCar        + " para " + SE1->E1_I_CART)
			    EndIf	
                nGravados++
			EndIf       
  		Else
  			aAdd( _aLog ,"4-Não houve alterações no seguinte título: " + SE1->E1_FILIAL+"/"+SE1->E1_NUM +"/" + SE1->E1_PARCELA + " do Cliente: " + SE1->E1_CLIENTE + "/" + SE1->E1_LOJA+ " - " + Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NREDUZ") )
  		EndIf	
	EndIf
    (_cAlias)->(DBSkip())
EndDo

//Volta o ambiente
nModulo := _nModOld
cModulo := _cModOld
cFilant := _cFilOld			

// Grava log
MFIN010LO(_aLog,oProc)

FWRESTAREA(_aArea)  

Return .T.

/*
===============================================================================================================================
Programa----------: MFIN10Val
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/08/2015
Descrição---------: Valida quantidade de títulos selecionados
Parametros--------: _cOrigem:= origem da chamada
Retorno-----------: .T ou .F.
===============================================================================================================================
*/   
User Function MFIN10Val(_cOrigem As Character,_xDado As Variant)

Local _lRet:= .T. As Logical

Do Case
	Case _cOrigem = "OK"
		If _nQtdTit == 0
			FWAlertWarning("Favor selecionar um ou mais títulos antes de realizar esta operação.","MFIN01002")
			_lRet:= .F.
		EndIf
	Case _cOrigem = "DATA"
        If _xDado < Date()
			FWAlertWarning("Data menor que hoje. Digite uma data maior que "+DToC(DATE()),"MFIN01003")
			_lRet:= .F.
		 ElseIf _xDado <> DataValida(_xDado)
			FWAlertWarning("Data digitada será alterada para o proximo dia util: "+DToC(DataValida(_xDado)),"MFIN01004")
			_xDado:=DataValida(_xDado)
		 EndIf
	Case _cOrigem = "CART"
        If !Empty(_xDado) .And. !EXISTCPO("ZAR",_xDado)
			_lRet:= .F.
		EndIf
EndCase

Return _lRet
                         
/*
===============================================================================================================================
Programa----------: MFIN010LO
Autor-------------: Josué Danich Prestes	
Data da Criacao---: 08/09/2015
Descrição---------: Rotina que permite gravar o LOG referente ao processamento
Parametros--------: _aLog - registro de eventos a ser salvo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN010LO(_aLog As Array,oProc As Object)

Local _aCols	:= {} As Array
Local _nI		:= 0 As Numeric
Local nConta	:= 0 As Numeric
Local _oFile	:= Nil As Object
Local _cArq2	:= SuperGetMV("IT_DIRLOG",.F.,"\temp\") + "MFIN010_" + DToS(DATE()) + "_"  As Character
Local _cTime 	:= Time() As Character

_cArq2 += SubStr(_cTime, 1, 2) + SubStr(_cTime, 4, 2) + SubStr(_cTime, 7, 2) + ".txt"
_oFile:= FWFileWriter():New(_cArq2)

If !_oFile:Create()
	FWAlertWarning("O arquivo de log padrão "+_cArq2+" nao pode ser criado!", "MFIN01005")
EndIf

aAdd( _aLog , "")
aAdd( _aLog ,"DATA DO FIM DO PROCESSAMENTO: "+ DToC( Date() )	)
aAdd( _aLog ,"HORA DO FIM DO PROCESSAMENTO: "+ Time() )

For _nI := 1 To Len(_aLog)
    nConta++
    oProc:cCaption := "Gravando Logs: "+AllTrim(Str(nConta))+ " de "+AllTrim(Str(Len(_aLog)))+", Alterados OK: "+AllTrim(Str(nGravados))
    ProcessMessages()

    If _oFile:Create()
	   _oFile:Write(_aLog[_nI]+CRLF)
	EndIf
    If _nI > nPulaLog .And. _nI < (Len(_aLog)-2)
       aAdd(_aCols, {LEFT(_aLog[_nI],1),SubStr(_aLog[_nI],3) } )
    EndIf   
Next _nI

If _oFile:Create()
   _oFile:Close()
EndIf

U_ITListBox("Log do processamento executado",;//, _aCols,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
            {"",'Observacoes das gravações'}    , _aCols, .T.    ,      ,         ,          ,;
            {10,     300                  }     ,         )
                                     // _aSizes , _nCampo , bOk , bCancel, _abuttons )
Return .T.

/*
===============================================================================================================================
Programa----------: MTAF001Tic
Autor-------------: Alex Wallauer
Data da Criacao---: 20/08/2018
Descricao---------: Tela de gets
Parametros--------: 
etorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN10Get()

Local oDlgGet := Nil As Object
Local nLinha :=05 As Numeric
Local nCol0  :=05 As Numeric
Local nCol1  :=17 As Numeric
Local nCol2  :=nCol1+45 As Numeric
Local nCol3  :=nCol2+20 As Numeric
Local nLarg1 :=55 As Numeric
Local nAltu1 :=12 As Numeric
Local nTam2  :=50 As Numeric
Local nPula  :=16 As Numeric
Local lOK    :=.F. As Logical
Local bOk    :={|| If(!_lData .Or. U_MFIN10Val("DATA",_dData), ( lOK:=.T. , oDlgGet:End() ) , ) } As Codeblock
Local bCancel:={|| lOK:=.F. , (oDlgGet:End()) } As Codeblock

If !U_MFIN10Val("OK")
   Return .F.
EndIf

DEFINE MSDIALOG oDlgGet TITLE "Altera Dados dos Titulo Marcados " FROM 0,0 TO 160,320 PIXEL
   
@001,001 MSPANEL oPanDesp Prompt "" Size 145,050 of oDlgGet

@nLinha,nCol0 CHECKBOX _lData PROMPT "" OF oPanDesp SIZE 040,040 ON CLICK ( If(_lData,_oData:Enable(),_oData:Disable()),_oData:Refresh() )
@nLinha,nCol1 Say "Data"          PIXEL OF oPanDesp
@nLinha,nCol2 MSGET _oData VAR _dData PIXEL SIZE nTam2,9 Picture "@D" OF oPanDesp WHEN _lData VALID U_MFIN10Val("DATA",_dData)
nLinha+=nPula

@nLinha,nCol0 CHECKBOX _lHist PROMPT "" OF oPanDesp SIZE 040,040 ON CLICK ( If(_lHist,_oHist:Enable(),_oHist:Disable()),_oHist:Refresh() )
@nLinha,nCol1 Say "Historico"     PIXEL OF oPanDesp
@nLinha,nCol2 MSGET _oHist VAR _cHist PIXEL SIZE nTam2+20,9 Picture "@!" OF oPanDesp WHEN _lHist VALID .T.
nLinha+=nPula

@nLinha,nCol0 CHECKBOX _lCart PROMPT "" OF oPanDesp SIZE 040,040 ON CLICK ( If(_lCart,_oCart:Enable(),_oCart:Disable()),_oCart:Refresh() )
@nLinha,nCol1 Say "Carteira CR" PIXEL OF oPanDesp
@nLinha,nCol2 MSGET _oCart VAR _cCart PIXEL SIZE nTam2,9 Picture "@!" OF oPanDesp WHEN _lCart VALID U_MFIN10Val("CART",_cCart) F3 "ZAR"
nLinha+=nPula

@nLinha,nCol1 BUTTON "Grava"   SIZE nLarg1,nAltu1 ACTION EVAL(bOk)

@nLinha,nCol3 BUTTON "Cancela" SIZE nLarg1,nAltu1 ACTION EVAL(bCancel)

oPanDesp:Align := CONTROL_ALIGN_TOP

ACTIVATE MSDIALOG oDlgGet CENTERED

Return lOK
