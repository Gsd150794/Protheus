/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/05/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |10/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RWMAKE.CH"

/*
===============================================================================================================================
Programa----------: MFIN004
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 22/10/2010
Descrição---------: Rotina para possibilitar a impressao de um/varios recibo(s) de pagamento onde o usuario podera realiazar 
                    a alteracao de algumas informacoes da baixa antes da impressao do recibo. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN004()

Private _cPerg		:= "MFIN004"
Private _oSelf		:= nil

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Imprime Recibo de pagamento"		,; // Descrição da Rotina
					{|_oSelf| MFIN004P() }					,; // Função do processamento
					"Rotina para imprimir vários recibos de pagamentos de títulos a Pagar." ,; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.F.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .T.                                              ) // Se .T. cria apenas uma regua de processamento.


Return                  

/*
===============================================================================================================================
Programa----------: MFIN004P
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Funcao usada para processar as baixas realizadas de acordo com os parametros fornecidos pelos usuarios e 
                    demonstrar em uma tela para que sejam selecionadas as desejadas para impressao. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN004P()    
                                   
Local oPanel
Local nHeight		:= 0
Local nWidth		:= 0
Local aSize			:= {}
Local aBotoes		:= {}
Local aCoors		:= {}
Local oOK			:= LoadBitmap(GetResources(),'LBOK')
Local oNO			:= LoadBitmap(GetResources(),'LBNO')
Local _cAlias		:= GetNextAlias()
Local _nX			:= 0
Private oDlg1            
Private nOpca		:= 0
Private nQtdTit		:= 0  
Private _aStru		:= {}            
Private aTitulo		:= {}       
Private aObjects	:= {}
Private aPosObj1	:= {}               
Private aInfo		:= {}    
Private oBrowse    
Private oFont12b                      
       
//===================================================================
// Define a fonte a ser utilizada no GRID                           
//===================================================================
Define Font oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito   

//Criando estrutura da tabela temporaria
aAdd(_aStru,{"E5_STATUS","C",02,00})
aAdd(_aStru,{"E5_PREFIXO","C",GetSX3Cache("E5_PREFIXO","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_TIPO","C",GetSX3Cache("E5_TIPO","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_NUMERO","C",GetSX3Cache("E5_NUMERO","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_PARCELA","C",GetSX3Cache("E5_PARCELA","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_CLIFOR","C",GetSX3Cache("E5_CLIFOR","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_LOJA","C",GetSX3Cache("E5_LOJA","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_BENEF","C",GetSX3Cache("E5_BENEF","X3_TAMANHO"),00})
aAdd(_aStru,{"A2_CGC","C",GetSX3Cache("A2_CGC","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_VALOR","N",GetSX3Cache("E2_VALOR","X3_TAMANHO"),GetSX3Cache("E2_VALOR","X3_DECIMAL")})
aAdd(_aStru,{"E5_DATA","D",GetSX3Cache("E5_DATA","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_NUMCHEQ","C",GetSX3Cache("E5_NUMCHEQ","X3_TAMANHO"),00})
aAdd(_aStru,{"E5_REFER","C",350,00  })
aAdd(_aStru,{"SE5RECNO","N",08,00})
                           
//Armazena no array aCampos o nome, descricao dos campos e picture
aAdd(aTitulo,{"E5_STATUS"  ,"  "," "})  
aAdd(aTitulo,{"E5_PREFIXO"  ,"PREFIXO"		,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_TIPO"    ,"TIPO"			,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_NUMERO"  ,"TITULO"		,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_PARCELA"  ,"PARCELA"		,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_CLIFOR"  ,"FORNECEDOR"	,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_LOJA"    ,"LOJA"			,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_BENEF"   ,"BENEFICIADO"	,"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"})//Picture passada desta forma para que o espacamento seja respeitado 
aAdd(aTitulo,{"A2_CGC"     ,"CPF/CNPJ"		,GetSX3Cache("A2_CGC","X3_PICTURE")})
aAdd(aTitulo,{"E5_VALOR"   ,"VALOR"			,"@E 999,999,999,999.99"})
aAdd(aTitulo,{"E5_DATA"  ,"DATA BAIXA"		,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_NUMCHEQ"  ,"NUM. CHEQUE"	,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E5_REFER"   ,"REFERENTE A"	,"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" }) 
aAdd(aTitulo,{"SE5RECNO"	,"RECNO"		,"@!"})

//===================================================================
// Seleciona os dados das baixas na tabela SE5                     
//===================================================================
_cQuery := "SELECT"  
_cQuery += " E5.E5_PREFIXO,E5.E5_NUMERO,E5.E5_PARCELA,E5.E5_CLIFOR,E5.E5_LOJA,E5.E5_BENEF,A2.A2_CGC,E5.E5_VALOR,E5.E5_DATA,E5.E5_TIPO,E5.E5_NUMCHEQ, E5.R_E_C_N_O_ SE5RECNO "
_cQuery += "FROM " + RetSqlName("SE5") + " E5, " + RetSqlName("SA2") + " A2 "
_cQuery += "WHERE E5.D_E_L_E_T_= ' '"
_cQuery += " AND A2.D_E_L_E_T_= ' '"
_cQuery += " AND A2.A2_COD = E5.E5_CLIFOR"
_cQuery += " AND A2.A2_LOJA = E5.E5_LOJA"
_cQuery += " AND E5.E5_RECPAG = 'P'"
_cQuery += " AND E5.E5_SITUACA <> 'C'"	
_cQuery += " AND E5.E5_FILIAL = '" + xFilial("SE5") + "'"
_cQuery += " AND A2.A2_FILIAL = '" + xFilial("SA2") + "'"	
_cQuery += " AND E5.E5_MOTBX = '"    + IIf(MV_PAR04 == 1,"NOR","DEB") +  "'" 
_cQuery += " AND E5.E5_DATA BETWEEN '"   + DToS(MV_PAR05) + "' AND '" + DToS(MV_PAR06) + "'" 	  
_cQuery += " AND E5.E5_CLIFOR BETWEEN '" + MV_PAR07        + "' AND '" + MV_PAR09         + "'" 
_cQuery += " AND E5.E5_LOJA BETWEEN '"   + MV_PAR08       + "' AND '" + MV_PAR10        + "'" 
If !Empty(MV_PAR01)  
	_cQuery += " AND E5.E5_BANCO = '"    + MV_PAR01    +  "'" 
EndIf  
If !Empty(MV_PAR02)
	_cQuery += " AND E5.E5_AGENCIA = '"  + MV_PAR02 +  "'"
EndIf  
If !Empty(MV_PAR03)
	_cQuery += " AND E5.E5_CONTA = '"    + MV_PAR03    +  "'" 
EndIf 

_oTempTable := FWTemporaryTable():New( _cAlias, _aStru )
_oTempTable:AddIndex( "01", {"E5_NUMERO","E5_PARCELA"} )
_oTempTable:AddIndex( "02", {"E5_CLIFOR", "E5_LOJA"} )
_oTempTable:AddIndex( "03", {"E5_BENEF"} )
_oTempTable:AddIndex( "04", {"E5_VALOR"} )
_oTempTable:AddIndex( "05", {"E5_DATA"} )
_oTempTable:Create()
SQLToTrb(_cQuery, _aStru, _cAlias)
(_cAlias)->( DBGoTop() )
			
//Faz o calculo automatico de dimensoes de objetos
aSize := MSADVSIZE()                    

//Obtem tamanhos das telas
aAdd( aObjects, { 0, 0, .T., .T., .T. } )

aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 } 
aPosObj1 := MsObjSize( aInfo, aObjects,  , .T. ) 
			
//Botoes da tela
aAdd( aBotoes, {"PESQUISA" ,{||xPesqTRB(_cAlias)},"Pesquisar...","Pesquisar"})
aAdd( aBotoes, {"S4WB005N" ,{||xVisuTRB(_cAlias)},"Visualizar Baixa..." ,"Baixa"})
aAdd( aBotoes, {'RELATORIO',{||MsgRun("Imprimindo Relatório Aguarde...",,{||CursorWait(),RelatSE5(_cAlias),CursorArrow()})},"Imprimir"})    
aAdd( aBotoes, {"RESPONSA" ,{||AtualzBaix(_cAlias)},"Alterar Dados para impressao...","Alterar"})

//Cria a tela para selecao dos Titulos                            
DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("ROTINA DE IMPRESSÃO DE RECIBO(S) DE PAGAMENTO") From 0,0 To aSize[6],aSize[5] OF oMainWnd PIXEL

oPanel       := TPanel():New(0,0,'',oDlg1,, .T., .T.,, ,315,30,.T.,.T. )
//oPanel:Align := CONTROL_ALIGN_TOP // Somente Interface MDI
			
@ 0.8 ,00.8 Say OemToAnsi("Quantidade:")        OF oPanel FONT oFont12b 
@ 0.8 ,0005 Say oQtda VAR nQtdTit Picture "@E 999999" SIZE 60,8 OF oPanel FONT oFont12b 

If FlatMode()
	aCoors := GetScreenRes()
	nHeight	:= aCoors[2]
	nWidth	:= aCoors[1]
Else
	nHeight	:= 143
	nWidth	:= 315
EndIf                    
			
oBrowse := TCBrowse():New( 35,01,aPosObj1[1,3] + 7,aPosObj1[1,4],,;
							,{20,20,20,02,09,02,02,10,06,04,54,08,08},;
                     	oDlg1,,,,,{||},,oFont12b,,,,,.F.,_cAlias,.T.,,.F.,,.T.,.T.)                                                                                               
For _nX:=1 to Len(_aStru)     
	If _aStru[_nX,1] == "E5_STATUS" 
		oBrowse:AddColumn(TCColumn():New("",{|| IIf((_cAlias)->E5_STATUS == Space(2),oNO,oOK)},,,,"CENTER",,.T.,.F.,,,,.F.,))
	Else
		oBrowse:AddColumn(TCColumn():New(OemToAnsi(aTitulo[_nX,2]),&("{ || " + (_cAlias) + '->' + _aStru[_nX,1]+"}"),aTitulo[_nX,3],,,If(_aStru[_nX,2]=="N","RIGHT","LEFT"),,.F.,.F.,,,,.F.,))
	EndIf
Next _nX

//Insere imagem em colunas que os dados poderao ser ordenados
inserPNG(4)	   

//Evento de duplo click na celula
oBrowse:bLDblClick   := {|| setStatus(_cAlias,(_cAlias)->E5_STATUS)}  
    
//Evento quando o usuario clica na coluna desejada
oBrowse:bHeaderClick := { |oBrowse, nCol| nColuna:= nCol,MsgRun("FAVOR AGUARDE, REALIZANDO OPERAÇÃO...",,{|| ordenaDado(_cAlias,nColuna) }) }

ACTIVATE MSDIALOG oDlg1 ON INIT (EnchoiceBar(oDlg1,{|| IIf(vldImpr(),Eval({|| nOpca := 1,oDlg1:End(),MsgRun("Imprimindo Relatório Aguarde...",,{||CursorWait(),RelatSE5(_cAlias),CursorArrow()})}),) },{|| nOpca := 2,oDlg1:End()},,aBotoes),oBrowse:Refresh())

//Fecha a area de uso do arquivo temporario no Protheus
(_cAlias)->(DBCloseArea())
_oTempTable:Delete()

Return

/*
===============================================================================================================================
Programa----------: setStatus
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Seta Status
Parametros--------: _cAlias,_cStatus
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function setStatus(_cAlias,_cStatus)

If _cStatus == Space(2)
	RecLock(_cAlias,.F.)
	(_cAlias)->E5_STATUS:= 'XX'
	nQtdTit++
	(_cAlias)->(MSUnLock())
Else
	RecLock(_cAlias,.F.)
	(_cAlias)->E5_STATUS:= Space(2)
	nQtdTit--
	(_cAlias)->(MSUnLock())
EndIf

nQtdTit:= IIf(nQtdTit<0,0,nQtdTit)

oQtda:Refresh()
oBrowse:DrawSelect()
oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: ordenaDado
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Seta Ordem
Parametros--------: _cAlias,nColuna
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ordenaDado(_cAlias,nColuna)

Local _aArea:= FWGetArea()

Do Case
	//Marca ou desmarca todos os titulos selecionados
	Case nColuna == 1
		(_cAlias)->(DBGoTop())
		While (_cAlias)->(!Eof())   
			//Se o titulo nao estiver selecionado
			If (_cAlias)->E5_STATUS == Space(2) 
				RecLock(_cAlias,.F.)	   		
				(_cAlias)->E5_STATUS:= 'XX'
				nQtdTit++
				(_cAlias)->(MSUnLock())  
			//Titulo selecionado
			Else
				RecLock(_cAlias,.F.)
				(_cAlias)->E5_STATUS:= Space(2)
				nQtdTit--
				(_cAlias)->(MSUnLock())
			EndIf      
      		(_cAlias)->(DBSkip())
		EndDo
   		nQtdTit:= IIf(nQtdTit<0,0,nQtdTit)        
		oQtda:Refresh()	   
		FWRestArea(_aArea)
	// Numero do Titulo  + Parcela
	Case nColuna == 4
		(_cAlias)->(DBSetOrder(1))
	// Codigo do Fornecedor + Loja
	Case nColuna == 6
		(_cAlias)->(DBSetOrder(2))
	// Nome do Fornecedor
	Case nColuna == 8
		(_cAlias)->(DBSetOrder(3))
	// valor da baixa
	Case nColuna == 10
		(_cAlias)->(DBSetOrder(4))
	// Data da baixa
	Case nColuna == 11
		(_cAlias)->(DBSetOrder(5))
EndCase

(_cAlias)->(DBGoTop())      
inserPNG(nColuna)                 
	
oBrowse:DrawSelect()   
oBrowse:Refresh(.T.)      
      
Return

/*
===============================================================================================================================
Programa----------: inserPNG
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 23/10/2010  
Descrição---------: Funcao para setar a coluna com uma imagem que significa que ela esta ordenada ou não.
Parametros--------: nCol = Numero de colunas.
Retorno-----------: Nenhum
===============================================================================================================================
*/                 
Static Function inserPNG(nCol)  

Local _aColunas := {}
Local _nX		:= 0
aAdd(_aColunas,{4})
aAdd(_aColunas,{6})
aAdd(_aColunas,{8})
aAdd(_aColunas,{10})
aAdd(_aColunas,{11})
                               

For _nX:=1 To Len(_aColunas)   
	// Seta as demais colunas como nao ordenadas
	If nCol <> _aColunas[_nX,1]   
		oBrowse:SetHeaderImage(_aColunas[_nX,1],"COLRIGHT") 
	// Seta a coluna com a imagem que significa que ela foi ordenada
	Else
		oBrowse:SetHeaderImage(_aColunas[_nX,1],"COLDOWN")
	EndIf
Next _nX

Return                                            

/*
===============================================================================================================================
Programa----------: xPesqTRB
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 23/10/2010  
Descrição---------: Funcao para pesquisa no arquivo temporario. 
Parametros--------: _cAlias = Alias da tabela.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function xPesqTRB(_cAlias)

Local oDlg
Local aComboBx1	 := {"Numero do Titulo+Parcela","Codigo+Loja","Beneficiario","Valor","Data da Baixa"}
Local nOpca      := 0
Local nI         := 0   

Private cGet1	 := Space(11) 
Private oGet1               
Private cComboBx1:= ""

//DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL
@ 178,181 TO 259,697 Dialog oDlg Title "Pesquisar"

@ 004,003 ComboBox cComboBx1 Items aComboBx1 Size 213,010 PIXEL OF oDlg ON CHANGE alteraMasc()
@ 020,003 MsGet oGet1 Var cGet1 Size 212,009 COLOR CLR_BLACK Picture "99999999999" PIXEL OF oDlg

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION (nOpca:=1,oDlg:End()) OF oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION (nOpca:=0,oDlg:End()) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1          
	If (Len(AllTrim(cGet1)) > 0 .And. Type("cGet1") == 'C') .Or. (Type("cGet1") == 'N' .And. cGet1 > 0 ) .Or. (Type("cGet1") == 'D' .And. cGet1 <> CtoD(" ") )
		For nI := 1 To Len(aComboBx1)
			If cComboBx1 == aComboBx1[nI]
				DBSelectArea(_cAlias)
				(_cAlias)->(DBSetOrder(nI))
				MsSeek(cGet1,.T.)
				oBrowse:DrawSelect()   
				oBrowse:Refresh(.T.)					 
			EndIf
		Next nI  
	Else     
		MsgStop("Favor informar um conteúdo a ser pesquisado. Para realizar a pesquisa é necessário que se forneça o conteúdo a ser pesquisado.","MFIN00402")
	EndIf
EndIf

Return

Static Function alteraMasc()

If cComboBx1 == "Numero do Titulo+Parcela"
	cGet1:= Space(11)  
	oGet1:Picture:= "99999999999"    
	ElseIf cComboBx1 == "Codigo+Loja"      
		cGet1:= Space(10)  
		oGet1:Picture:= "@!"  
	ElseIf cComboBx1 == "Beneficiario"
		cGet1:= Space(30)  
		oGet1:Picture:= "@!"     
	 ElseIf cComboBx1 == "Valor"
		cGet1:= Space(17)  
		oGet1:Picture:= PesqPict("SE5","E5_VALOR")  
		cGet1:= 0
	 ElseIf cComboBx1 == "Data da Baixa"
		cGet1:= CtoD(" ") 
		oGet1:Picture:= PesqPict("SE5","E5_DATA")     
	EndIf
	oGet1:SetFocus()
Return

/*
===============================================================================================================================
Programa----------: xVisuTRB
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Exibe na tela os dados da tabela posicinada.
Parametros--------: _cAlias = Alias da tabela.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function xVisuTRB(_cAlias)

Local _aArea   := FWGetArea() 

DBSelectArea("SE2")
SE2->(DBSetOrder(1))
If SE2->(DBSeek(xFilial("SE2") + (_cAlias)->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA)))
	Fc050Con()
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AtualzBaix
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Permite alterar os dados da baixa para impressão.
Parametros--------: _cAlias = Alias da tabela.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AtualzBaix(_cAlias)  

Local oDlg    
Local nopc     := 0   
Local _aTxtDet := {}   
Local _cNomeFor:= Space(30)   
Local _cCPFCNPJ:= Space(18)   
Local _aArea   := FWGetArea()
Local _nValor	:= (_cAlias)->E5_VALOR
Private cObs   := (_cAlias)->E5_REFER

DEFINE MSDIALOG oDlg FROM	08,0 TO 33,75 TITLE "ALTERAR DADOS DA BAIXA PARA IMPRESSAO" OF oMainWnd  //"Consulta - T¡tulos a Pagar"

_cNomeFor:= (_cAlias)->E5_BENEF
_cCPFCNPJ:= IIf(Len(AllTrim((_cAlias)->A2_CGC)) == 11,Transform((_cAlias)->A2_CGC,"@R 999.999.999-99"),Transform((_cAlias)->A2_CGC,"@R! NN.NNN.NNN/NNNN-99"))

@ 34, 003 Say  	"Prf"						SIZE 16, 07						OF oDlg PIXEL
@ 41, 003 MSGET (_cAlias)->E5_PREFIXO		SIZE 16, 09 When .F. 			OF oDlg PIXEL 
@ 34, 023 Say  	"Titulo"    				SIZE 21, 07						OF oDlg PIXEL  //"T¡tulo"
@ 41, 023 MSGET (_cAlias)->E5_NUMERO 		SIZE 46, 09 When .F. 			OF oDlg PIXEL
@ 34, 073 Say  	"Parc"    					SIZE 16, 07						OF oDlg PIXEL  //"Parc"
@ 41, 073 MSGET (_cAlias)->E5_PARCELA 		SIZE 11, 09 When .F. 			OF oDlg PIXEL
@ 34, 087 Say  "Tipo"    					SIZE 16, 07						OF oDlg PIXEL  //"Tipo"
@ 41, 087 MSGET (_cAlias)->E5_TIPO 			SIZE 13, 09 When .F. 			OF oDlg PIXEL

@ 54, 003 Say   "Fornecedor"				SIZE 030, 07 					OF oDlg PIXEL  //"Fornec."
@ 61, 003 MSGET (_cAlias)->E5_CLIFOR 		SIZE 070, 09 When .F.       	OF oDlg PIXEL 
@ 54, 078 Say   "Loja"						SIZE 016, 07 					OF oDlg PIXEL  //"Loja"
@ 61, 078 MSGET (_cAlias)->E5_LOJA 			SIZE 021, 09 When .F. 			OF oDlg PIXEL
@ 54, 108 Say   "Nome"	     				SIZE 030, 07 					OF oDlg PIXEL  //"Nome"
@ 61, 108 MSGET oNomFor VAR _cNomeFor       SIZE 103, 09 When .T. 			OF oDlg PIXEL PICTURE "@!"  
@ 54, 220 Say   "CPF/CNPJ"	     			SIZE 030, 07 					OF oDlg PIXEL  //"CPF/CNPJ"
@ 61, 220 MSGET oCPFCNPJ  VAR _cCPFCNPJ     SIZE 68, 09  When .T. 			OF oDlg PIXEL PICTURE "@!"  

@ 75, 003 Say  "Data da Baixa" 		        SIZE 42, 07						OF oDlg PIXEL  //"Data da baixa" 
@ 82, 003 MSGET DToC((_cAlias)->E5_DATA) 	SIZE 68, 09  When .F.       	OF oDlg PIXEL PICTURE PesqPict("SE5","E5_DATA")        
@ 75, 073 Say  "Valor da Baixa" 	     	SIZE 45, 07						OF oDlg PIXEL  //"Juros Devidos"
@ 82, 073 MSGET _nValor 					SIZE 68, 09 PICTURE Tm(_nValor,17,2)  When .F.	OF oDlg PIXEL   		
@ 75, 143 Say  "Numero Cheque" 	     		SIZE 45, 07						      OF oDlg PIXEL  //"Numero do Cheque"
@ 82, 143 MSGET (_cAlias)->E5_NUMCHEQ 		SIZE 68, 09 PICTURE "@!" When .F. OF oDlg PIXEL		
@ 111, 003 Say  "Referente a:" 	     	    SIZE 45, 07						  OF oDlg PIXEL  //"Numero do Cheque"                      	
@ 118, 003 GET oObs VAR cObs OF oDlg MULTILINE SIZE 210, 058 COLORS 0, 16777215 HSCROLL PIXEL

ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{||nopc:=1,oDlg:End()}, {||oDlg:End()},,)  

If nopc == 1
	//======================================
	// Impressao dos dados do campo Memo
	//======================================
    /*
	Q_MemoArray(mMemo, aTxtDet, nTamQuebra)
	mMemo = Variavel que contem o conteudo do campo memo
	aTxtDet = Array que gostaria que tivesse o conteudo do campo memo
	nTamQuebra = Posição para quebra da linha
    */
	Q_MemoArray(cObs,_aTxtDet,85)
	If Len(_aTxtDet) > 0
		_cDadosMemo:= ImpMemo(_aTxtDet) //Funcao utilzada para imprimir campo Memo
	EndIf

	RecLock(_cAlias,.F.)
	(_cAlias)->E5_BENEF  := _cNomeFor
	(_cAlias)->A2_CGC    := _cCPFCNPJ
	(_cAlias)->E5_REFER  := _cDadosMemo
	(_cAlias)->(MSUnLock())
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: RelatSE5
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Funcao usada para imprir os recibos de pagamentos selecionados pelo usuario.
Parametros--------: _cAlias = Alias da tabela.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RelatSE5(_cAlias)     

Local _aArea		:= FWGetArea()
Local nImpres		:= 2
Local lImpres
Local _nNumLinh		:= 1
Private oFont09
Private oFont09b
Private oFont10
Private oFont10b
Private oFont12
Private oFont12b
Private oFont16b
Private oFont14
Private oFont14b
Private oPrint
Private nLinha		:= 0100
Private nColInic	:= 0030
Private nColFinal	:= 2360 
Private nLinInBox
Private nSaltoLinha	:= 50               
Private nLinFinBox
//Private oBrush		:= TBrush():New( ,CLR_LIGHTGRAY)   
Private _aDadosAgl	:= {}

Define Font oFont09    Name "Courier New"       Size 0,-07       // Tamanho 14                                                                              
Define Font oFont09b   Name "Courier New"       Size 0,-07 Bold  // Tamanho 14                                                                              
Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14 
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         
Define Font oFont16b   Name "Courier New"       Size 0,-16 Bold  // Tamanho 14  

//====================================================================               
// Verifica se foi selecionada pelo menos uma baixa para impressao
//====================================================================
If vldImpr()
    //=============================================================================================
	// Efetua a aglutinacao dos Dados por numero de cheque conforme solicitado pelo analista Tiago
	//=============================================================================================
	_aDadosAgl:= aglutDados(_cAlias)

	oPrint:= TMSPrinter():New("RECIBO DE PAGAMENTO") 
	oPrint:SetPortrait() 	// Retrato  oPrint:SetLandscape() - Paisagem
	oPrint:SetPaperSize(9)	// Seta para papel A4
	
	//====================================================================	                 		
	// startando a impressora
	//====================================================================
	oPrint:Say(0,0," ",oFont12,100)         
	     
	For _nNumLinh:=1 to Len(_aDadosAgl)
				 
				If nImpres > 3 .And. nImpres % 2 == 0 
					oPrint:EndPage()	// Finaliza a Pagina.
				EndIf  
				          
		   		If nImpres % 2 == 0  
				    //===========================                                       
					// Inicia uma nova pagina
					//=========================== 
					oPrint:StartPage()        
			
					nLinha    := 0100 
					nLinInBox := 0100
					nLinFinBox:= 1600   
					
					lImpres   := .F.
					
						Else
								nLinha    := 1800   
								nLinInBox := 1800
								nLinFinBox:= 3300 								
								
								lImpres   := .T.  									
				EndIf         
	         						
		impDados(_nNumLinh) 
		
		nImpres++						 
	
	Next _nNumLinh  
	
	If !lImpres           
		oPrint:EndPage()	// Finaliza a Pagina.
	EndIf
	
	oPrint:Preview()	// Visualiza antes de Imprimir. 
	
	oDlg1:End() 
	
EndIf	

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: impDados
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Imprime os dados do recibo de pagamento.
Parametros--------: n = Posição do array _aDadosAgl.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function impDados(n)

Local cRaizServer := If(issrvunix(), "/", "\")
Local nValor

oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)
oPrint:Say (nlinha + 25,nColFinal / 2,"RECIBO DE PAGAMENTO",oFont16b,nColFinal,,,2)
nlinha+=nSaltoLinha
nlinha+=nSaltoLinha
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)

nlinha+=nSaltoLinha
oPrint:Say (nlinha,nColInic + 10 ,"Titulo/Parcela:",oFont12b)
oPrint:Say (nlinha,nColInic + 350,IIf(_aDadosAgl[n,13],"",_aDadosAgl[n,3] + '/' + _aDadosAgl[n,4]),oFont12)
nlinha+=nSaltoLinha

If Len(AllTrim(_aDadosAgl[n,11])) > 0
	oPrint:Say (nlinha,nColInic + 10 ,"Cheque........:",oFont12b)
	oPrint:Say (nlinha,nColInic + 350,_aDadosAgl[n,11],oFont12)
	nlinha+=nSaltoLinha
EndIf
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 10 ,"Recebemos de..:",oFont12b)
oPrint:Say (nlinha,nColInic + 350 ,AllTrim(SM0->M0_NOMECOM),oFont12)
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 10 ,"CNPJ..........:",oFont12b)
oPrint:Say (nlinha,nColInic + 350 ,Transform(SM0->M0_CGC,"@R! NN.NNN.NNN/NNNN-99"),oFont12)
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 10 ,"Estabelecida a:",oFont12b)
oPrint:Say (nlinha,nColInic + 350 ,AllTrim(SM0->M0_ENDENT),oFont12)
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 10 ,"Cidade de.....:",oFont12b)
oPrint:Say (nlinha,nColInic + 350 ,AllTrim(SM0->M0_CIDENT) + ' - ' + SM0->M0_ESTENT,oFont12)
nlinha+=nSaltoLinha
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 10 ,"A quantida de.:",oFont12b)
nValor:= _aDadosAgl[n,9]
impRefer('R$ ' + AllTrim(Transform(nValor,PesqPict("SE5","E5_VALOR"))) + " (" + AllTrim(extenso(nValor)) + ")",oFont12b,350,85)

oPrint:Say (nlinha,nColInic + 10 ,"Referente a...:",oFont12b)
impRefer(AllTrim(_aDadosAgl[n,12]),oFont12,350,85)
nlinha+=nSaltoLinha

nlinha:= nLinFinBox - 500
oPrint:Box(nlinha - 50 ,nColInic +300,nLinFinBox - 50,nColFinal - 300)
oPrint:Say (nlinha,nColInic + 315 ,"E por ser verdade firmamos o presente recibo.",oFont12)

nlinha+=nSaltoLinha
oPrint:Say (nlinha,nColFinal / 2,AllTrim(SM0->M0_CIDENT) + ' - ' + SM0->M0_ESTENT + ', ' + AllTrim(Str(DAY(_aDadosAgl[n,10]))) + ' de ' + AllTrim(MesExtenso(Month(_aDadosAgl[n,10])))+ " de " + AllTrim(Str(YEAR(_aDadosAgl[n,10]))),oFont12,nColFinal,,,2)

nlinha+=nSaltoLinha
nlinha+=nSaltoLinha
nlinha+=nSaltoLinha

oPrint:Line(nLinha,nColInic + 330,nLinha,nColFinal - 330)
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 315 ,"Beneficiario:",oFont12b)
oPrint:Say (nlinha,nColInic + 615 ,SubStr(_aDadosAgl[n,7],1,60),oFont12)
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 315 ,"CPF/CNPJ....:",oFont12b)

//Se caso tenha sido aglutinado verifica se o CPF/CNPJ dos titulos aglutinados sao os mesmos para todos os titulos
oPrint:Say (nlinha,nColInic + 615 ,IIf(_aDadosAgl[n,13],IIf(_aDadosAgl[n,14],_aDadosAgl[n,8],""),_aDadosAgl[n,8]),oFont12)
nlinha+=nSaltoLinha

oPrint:Say (nlinha,nColInic + 315 ,"Endereço....:",oFont12b)

// Caso nao tenha sido aglutinado por numero do cheque ou caso tenha aglutinado e o codigo do fornecedor e loja sejam iguais para 
// todos os titulos aglutinados
If !_aDadosAgl[n,13] .Or. _aDadosAgl[n,15]
	// Obtem dados do Endereco
	DBSelectArea("SA2")
	SA2->(DBSetOrder(1))
	If SA2->(DBSeek(xFilial("SA2") + _aDadosAgl[n,5] + _aDadosAgl[n,6]))
		_cDadosEnd:= AllTrim(SA2->A2_END) + ' - ' + AllTrim(SA2->A2_MUN) + ' ' + SA2->A2_EST
		impRefer(AllTrim(_cDadosEnd),oFont12,615,60)
	EndIf
EndIf

oPrint:Box(nLinInBox,nColInic,nLinFinBox,nColFinal)

Return

/*
===============================================================================================================================
Programa----------: vldImpr
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Valida a impressão do recibo de pagamento.
Parametros--------: Nenhum
Retorno-----------: lRet = .T. = recibo Ok para impressão.
                         = .F. = recibo não está OK para impressão.
===============================================================================================================================
*/
Static Function vldImpr() 

Local lRet   := .T.  
Local _aArea := FWGetArea()

If nQtdTit == 0 
	MsgStop("Não foram selecionadas baixas para impressão do recibo de pagamento. Favor selecionar uma ou mais baixas para impressão.","MFIN00401")
	lRet:= .F.
EndIf        

FWRestArea(_aArea)

Return lRet                        

/*
===============================================================================================================================
Programa----------: ImpMemo
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Concatena o texto do array passado como parâmetro, transformando-o em uma única linha de texto.
Parametros--------: msgValor = Array com textos a serem transformados em frase em linha única.
Retorno-----------: cRet = Texto concatenado e transformado em uma unica linha de texto.
===============================================================================================================================
*/
Static Function ImpMemo(msgValor)      
     
Local nAux	:=1
Local cRet	:= ""

While nAux <= Len(msgValor)
	cRet+= AllTrim(msgValor[nAux]) + ' '
	nAux++
EndDo

Return cRet
    
/*
===============================================================================================================================
Programa----------: impRefer
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Funcao desenvolvida para possibilitar a impressao dos dados de forma que a impressao nao quebra a palavra 
                    ao mudar de linha.  
Parametros--------: cReferente = Texto a ser convertido em array e impresso.
                    oFont = Fonte de impressão.
                    nAlinham = numero de colunas para alinhamanto.
                    nCaract = Numero de colunas.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function impRefer(cReferente,oFont,nAlinham,nCaract)

Local _aDadosRef:= StrTokArr(cReferente," ")  
Local _cAux		:= ""
Local _nCaracCol:= nCaract 
Local _cTextImpr:= ""
Local _nX		:= 0

For _nX:= 1 To Len(_aDadosRef)
	If (Len(_cTextImpr) + Len(_aDadosRef[_nX])) <= _nCaracCol 
	 	_cTextImpr+= _aDadosRef[_nX]+ ' '
	Else
	   	_cAux+= _cTextImpr
		oPrint:Say (nlinha,nColInic + nAlinham ,AllTrim(_cTextImpr),oFont)
		nlinha+=nSaltoLinha
		_cTextImpr:= _aDadosRef[_nX]+ ' '
	EndIf
Next _nX

If Len(_cAux) < Len(cReferente)
	oPrint:Say (nlinha,nColInic + nAlinham ,AllTrim(_cTextImpr),oFont)
	nlinha+=nSaltoLinha
EndIf

Return

/*
===============================================================================================================================
Programa----------: aglutDados
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010   
Descrição---------: Aglutina alguns dados da tabela passada como parâmetro e retorna em uma array.
Parametros--------: _cAlias = Alias da tabela.
Retorno-----------: _aDadosAgl = array com os dados da tabela passada como parâmetro aglutinado.
===============================================================================================================================
*/
Static Function aglutDados(_cAlias)

Local _aDadosAgl:= {}
Local nPosCheque:= 0

(_cAlias)->(DBGoTop())

// Percorre todos os registros da tela para verificar quais foram selecionados para impressao
While (_cAlias)->(!Eof())

	// Verifica se o registro corrente foi selecionado
	If (_cAlias)->E5_STATUS == 'XX'
		If Len(AllTrim((_cAlias)->E5_NUMCHEQ)) > 0
			nPosCheque:= aScan(_aDadosAgl,{|x| x[11] == (_cAlias)->E5_NUMCHEQ })
			If nPosCheque == 0
				aAdd(_aDadosAgl,{(_cAlias)->E5_PREFIXO,(_cAlias)->E5_TIPO,(_cAlias)->E5_NUMERO,;
				                 (_cAlias)->E5_PARCELA,(_cAlias)->E5_CLIFOR,(_cAlias)->E5_LOJA,;
				                 (_cAlias)->E5_BENEF,(_cAlias)->A2_CGC,(_cAlias)->E5_VALOR,;
				                 (_cAlias)->E5_DATA,(_cAlias)->E5_NUMCHEQ,(_cAlias)->E5_REFER,.F.,.T.,.T.})
			Else
				_aDadosAgl[nPosCheque,9] += (_cAlias)->E5_VALOR
				_aDadosAgl[nPosCheque,13]:= .T.
				// Verifica se na aglutinacao por Cheque eh o mesmo CPF/CGC para impressao no recibo de pagamento.
				If _aDadosAgl[nPosCheque,14]
					If _aDadosAgl[nPosCheque,8] <> (_cAlias)->A2_CGC
							_aDadosAgl[nPosCheque,14]:= .F.
					EndIf
				EndIf
					// Verifica se na aglutinacao por Cheque eh o mesmo CPF/CGC para impressao no recibo de pagamento.
					If _aDadosAgl[nPosCheque,15]
						If _aDadosAgl[nPosCheque,5] + _aDadosAgl[nPosCheque,6] <> (_cAlias)->(E5_CLIFOR+E5_LOJA)
							_aDadosAgl[nPosCheque,15]:= .F.
						EndIf
					EndIf
			EndIf
		Else
			aAdd(_aDadosAgl,{(_cAlias)->E5_PREFIXO,(_cAlias)->E5_TIPO,(_cAlias)->E5_NUMERO,;
			                 (_cAlias)->E5_PARCELA,(_cAlias)->E5_CLIFOR,(_cAlias)->E5_LOJA,;
			                 (_cAlias)->E5_BENEF,(_cAlias)->A2_CGC,(_cAlias)->E5_VALOR,;
			                 (_cAlias)->E5_DATA,(_cAlias)->E5_NUMCHEQ,(_cAlias)->E5_REFER,.F.})
		EndIf
	EndIf

	(_cAlias)->(DBSkip())		
EndDo

Return _aDadosAgl
