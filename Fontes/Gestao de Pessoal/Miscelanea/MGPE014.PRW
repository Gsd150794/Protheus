/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |18/12/2019| Chamado 31486. Correção da geração do arquivo para usar os campos R0_DIASPRO e RG2_DIAPRO. 
Igor Melgaço  |17/07/2023| Chamado 44157. Ajuste para não incluir funcionários demitidos na listagem. 
Lucas Borges  |28/08/2024| Chamado 48256. Incluído abatimento das faltas. 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE014
Autor-------------: Josué Danich Prestes
Data da Criacao---: 16/03/2016
Descrição---------: INTEGRACAO DE BENEFICIOS COM EMPRESA SE SERVICOS - Chamado 10177
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE014()

Pergunte('MGPE014',.F.)

TNewProcess():New("MGPE014", "Exportacao dos arquivos de beneficios",;
					 {|oSelf| MGPE014PB(oSelf)}, "Esta rotina Processa e gera arquivo de beneficios para integracao",;
					  "MGPE014", NIL, NIL, NIL, NIL, .T., .F.) 
Return


/*
===============================================================================================================================
Programa----------: MGPE014PB
Autor-------------: Josué Danich Prestes
Data da Criacao---: 22/01/2016
Descrição---------: Processa Beneficios
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE014PB(_oProcess)

Local _aArea     := FWGetArea()

Private _nTotal  := 0
Private _nVlr    := 0
Private _nHdl    := 0
Private _nLin    := 0
Private _lImpLis := IIf(MV_PAR12 == 1,.T.,.F.)   //Impressao Relatorio
Private _nOrd    := MV_PAR13                   //Ordem Relatorio
Private _cArqOut   := ""
Private _lErrorImp := .F.
Private nConta:=0


DBSelectArea( "RG2" )
RG2->( DBSetOrder(1) )

_oProcess:SetRegua1(7) //Total de elementos da regua
_oProcess:SaveLog("Inicio de processamento")       

MGPE014PI(_oProcess) 

//Fecha Arquivo
If _nHdl > 0

	If !FClose(_nHdl)

		MsgAlert('Ocorreram problemas no fechamento do arquivo.',"MGPE01401") 

	EndIf

EndIf

//Encerra o processamento
If !_oProcess:lEnd

	_oProcess:SaveLog("Fim do processamento") 
	
	If _lErrorImp

		fErase( _cArqOut )
		MsgAlert("Existe dados inválidos. Verifique o Log de Processos desta rotina!","MGPE01402")
		
	ElseIf _nLin > 0
		MsgInfo("Fim do Processamento","MGPE01403")
		 //Imprime Listagem
		 If _lImpLis
			 MGPE014FI()
		 EndIf

 	Else
		Aviso("MGPE01404", "Não existem registros a serem gravados." ,{"Ok"}) 
	EndIf

Else

	_nLin := 0
	Aviso("MGPE01405", "Processamento cancelado pelo usuario!" , {"Ok"}) 
	_oProcess:SaveLog("Processamento cancelado pelo usuario!")

EndIf

FWRestArea(_aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: MGPE014PI
Autor-------------: Josué Danich Prestes
Data da Criacao---: 22/01/2016
Descrição---------: Inicializa e faz query de Beneficios
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE014PI(_oProcess)

Local _cQuery    := ''
Local _cArqIni   := ""
Local _cFuncVal  := ""
Local _nCount    := 0
Local _nPos      := 0
Local _cMyChave  := ""
Local _nAux      := 0
Local _nTp		   := 0
Local _nLinha

Private _cSRA_End := ''
Private _cSRA_Num := ''
Private _cRGC_End := ''
Private _cRGC_Num := ''

Private _cFornecedor   := 0
Private _nseq    := 0
Private _dCred   := cTod(" / / ")
Private _aStruct

Private _nTotReg     := 0	//-Qtd.Registros - no arquivo
Private _nTotRegTP1  := 0	//-Qtd.Registros - Tipo 1
Private _nTotRegTP2  := 0	//-Qtd.Registros - Tipo 2
Private _nTotRegTP3  := 0	//-Qtd.Registros - Tipo 3
Private _nTotRegTP4  := 0	//-Qtd.Registros - Tipo 4
Private _nTotRegTP5  := 0	//-Qtd.Registros - Tipo 5
Private _nQtdTotItem := 0
Private _nVlrTotItem := 0

Private _nPosEnd := 0
Private _nSeqEnd := 0
Private _aSeqEnd := {}

//Carrega Perguntas
_cFornecedor := MV_PAR01                     //Fornecedor selecionado
_cTiposSel   := MV_PAR02                     //Tipos Selecionados
_cPeriodo    := SubStr(AllTrim(MV_PAR03),4,4) + SubStr(AllTrim(MV_PAR03),1,2)      //Periodo
_cFilDe      := MV_PAR04                     //Da Filial
_cFilAte     := MV_PAR05                     //Ate a Filial
_cCcDe       := MV_PAR06                     //Do Centro Custo
_cCcAte      := MV_PAR07                     //Ate Centro de Custo
_cMatDe      := MV_PAR08                     //Da Matricula
_cMatAte     := MV_PAR09                     //Ate Matricula
_dCred       := MV_PAR10                     //Data Credito
_cAdm        := DToS(MV_PAR11)               //Consid.Admitido Ate

//====================================================================================================
// Verifica parametros                                                    
//====================================================================================================
If Empty(_cFornecedor)
    MsgAlert("Parâmetro sobre fornecedor não preenchido!","MGPE01406")
    Return
EndIf

If Empty(_cAdm)
    MsgAlert("Parâmetro sobre data de admissão não preenchido!","MGPE01407")
    Return
EndIf

If Empty(_cTiposSel)
	MsgAlert("Parâmetro sobre tipos de beneficio não preenchido!","MGPE01408")
    Return
EndIf

//====================================================================================================
// Verifica se foi informado os Arquivos .INI e de Saida                  
//====================================================================================================
_nLinha  := FPOSTAB("S018", AllTrim(_cFornecedor), "==", 4)

If Empty( _cArqIni := AllTrim(FTABELA("S018", _nLinha, 08)) )
	MsgAlert("Arquivo .INI não informado na Tabela Auxiliar S018!","MGPE01409")
	Return
EndIf

If Empty( _cArqOut := AllTrim(FTABELA("S018", _nLinha, 09)) )
	MsgAlert("Arquivo de Saída não informado na Tabela Auxiliar S018","MGPE01410")
	Return
EndIf

If Empty( _cFuncVal := AllTrim(FTABELA("S018", _nLinha, 10)) )
	MsgAlert("Função de Validação não informada na Tabela Auxiliar S018","MGPE01411")
	Return
Else

	If At("(", _cFuncVal ) > 0
    	MsgAlert("Função validadora com caracter -()- invalido, na tabela S018","MGPE01412")
    	Return
 	EndIf   

EndIf

If !file( _cArqIni )
    MsgAlert("Arquivo de inicialização não localizado: " +' - ' +_cArqIni,"MGPE01413")
    Return
EndIf

If File( _cArqOut )
   If Aviso("MGPE01414", _cArqOut +" - " +"Arquivo Já Existe. Sobrepor?" ,{"Não","Sim"}) == 1  
      Return
   EndIf
EndIf

//Executa funcao padrao para processar arquivo INI
_aStruct := RHProcessaIni(_cArqIni)

//Cria Arquivo de saida
_nHdl := FCreate(_cArqOut)

If _nHdl == -1

	MsgAlert('O arquivo '+_cArqOut+' não pode ser criado! Verifique os parametros.',"MGPE01415") 
	Return

EndIf

//-------------------------------------------------------------------------------------//
// Codigo 0 - Header do Arquivo					                                         //
//-------------------------------------------------------------------------------------//
_nseq++ 
_oProcess:IncRegua1("Header de arquivo")
FWrite( _nHdl, RHGeraLinhas( _aStruct[1] ) )

//-------------------------------------------------------------------------------------//
// Codigo 1 - Empresas/Enderecos  				                                         //
//
// Faz um Loop pois o RHGeralinhas só faz a linha do RGC que estiver posicionado     
//-------------------------------------------------------------------------------------//
_nTotRegTP1 := 1

_nseq++ 
_oProcess:IncRegua1("Empresas/Enderecos")

RGC->( DBGoTop() )

While .not. RGC->( Eof() )

	FWrite( _nHdl, RHGeraLinhas( _aStruct[2], "01" ) )
	
	RGC->( DBSkip())
	
EndDo
	
//-------------------------------------------------------------------------------------//
// Prepara Enderecos de Entrega				                                       //
//-------------------------------------------------------------------------------------//

_cQuery  := " SELECT DISTINCT RA_LOCBNF, RA_FILIAL,RA_MAT "
_cQuery  += " FROM " + RetSqlName("SRA") + " SRA "
_cQuery  += " WHERE "
_cQuery  += " SRA.D_E_L_E_T_ = ' ' "
_cQuery  += " AND RA_FILIAL >= '" + _cFilDe + "' AND RA_FILIAL <= '" + _cFilAte + "' "
_cQuery  += " AND RA_CC >= '" + _cCcDe + "' AND RA_CC <= '" + _cCcAte + "' "
_cQuery  += " AND RA_MAT >= '" + _cMatDe + "' AND RA_MAT <= '" + _cMatAte + "' "
_cQuery  += " AND RA_ADMISSA <= '" + _cAdm + "' "
_cQuery  += " ORDER BY RA_LOCBNF,RA_FILIAL,RA_MAT "

//Verifica Tabela Aberta
If Select("QD02VB") > 0
	
	DBSelectArea("QD02VB")
	DBCloseArea()

EndIf

//Abrir Tabela
DbUseArea( .T., "TOPCONN", TcGenQry( ,, _cQuery), "QD02VB", .T., .F.)
QD02VB->(DBGoTop())

_nSeqEnd := 0
_aSeqEnd := {}
_cMyChave := ""

While QD02VB->(!Eof())

	//-Gera apenas 1 linha por Loc.Entrega
	If QD02VB->RA_LOCBNF == _cMyChave 
		QD02VB->(DBSkip())
		Loop
	Else
		_cMyChave := QD02VB->RA_LOCBNF
	EndIf
	
	DBSelectArea("RGC")
	DBSetOrder(1)	//-RGC_FILIAL+RGC_KEYLOC
	DBSeek(xFilial("RGC")+QD02VB->RA_LOCBNF,.F.)
	
	//Separa Numero do Endereco
	_cRGC_End := ''
	_cRGC_Num := ''
	If (_nPos := Rat(",",RGC_ENDER)) > 0
		_cRGC_End := SubStr(RGC_ENDER,1,_nPos - 1)
		_cRGC_Num := SubStr(RGC_ENDER,_nPos + 1)
	EndIf
	
	//-Cria sequencia de Enderecos
	_nSeqEnd += 1
	aAdd(_aSeqEnd, {QD02VB->RA_LOCBNF, _nSeqEnd})
	
	QD02VB->(DBSkip())

EndDo

//-Ajusta o conteudo da _cTiposSel pra usar na Query
_cQryAux := ""
_cTiposSel := AllTrim(_cTiposSel)

For _nTp := 1 to Len(_cTiposSel) Step 2

	_cQryAux += "'"+SubStr(_cTiposSel, _nTp, 2)+"'"

	If (_nTp + 2) < Len(_cTiposSel)

		_cQryAux += ","

	EndIf

Next _nTp

//---------------------------------------------------------------------------------//
// Codigo 2 - Funcionarios						                                                //
//--------------------------------------------------------------------------------//
_nTotRegTP2 := 0 
_oProcess:IncRegua1("Funcionarios")

_cQuery  := "SELECT RG2_FILIAL,"
_cQuery  += " RG2_VALCAL,"  
_cQuery  += " RG2_MAT,"  
_cQuery  += " RG2_TPBEN,"  
_cQuery  += " RG2_DIAPRO-RG2_FALTAS RG2_DUTILM,"  
_cQuery  += " RG2_CODIGO,"  
_cQuery  += " RG2_VTDUTE,"  
_cQuery  += " RA_FILIAL,"
_cQuery  += " RA_CC,"
_cQuery  += " RA_MAT,"
_cQuery  += " RA_NOME,"
_cQuery  += " RA_ADMISSA,"
_cQuery  += " RA_DEMISSA,"
_cQuery  += " RA_LOCBNF,"
_cQuery  += " RA_ENDEREC,"
_cQuery  += " RA_COMPLEM,"
_cQuery  += " RA_BAIRRO,"
_cQuery  += " RA_MUNICIP,"
_cQuery  += " RA_ESTADO,"
_cQuery  += " RA_ESTADO,"
_cQuery  += " RA_CEP,"
_cQuery  += " RA_TELEFON,"
_cQuery  += " RA_NASC,"
_cQuery  += " RA_CIC,"
_cQuery  += " RA_RG,"
_cQuery  += " RA_MAE,"
_cQuery  += " RA_EMAIL,"
_cQuery  += " RA_ESTCIVI,"
_cQuery  += " RA_SEXO,"
_cQuery  += " RA_PAI,"
_cQuery  += " RA_RGUF,"
_cQuery  += " RA_LOGRNUM,"
_cQuery  += " RA_LOGRDSC "

_cQuery  += " FROM " + RetSqlName("RG2") + " RG2 "
_cQuery  += " INNER JOIN " + RetSqlName("SRA") + " SRA "
_cQuery  += " ON SRA.RA_MAT = RG2.RG2_MAT AND SRA.RA_FILIAL = RG2.RG2_FILIAL "

_cQuery  += " WHERE "
_cQuery  += " RG2.D_E_L_E_T_ = ' ' AND SRA.D_E_L_E_T_ = ' ' "
_cQuery  += " AND RA_FILIAL >= '" + _cFilDe + "' AND RA_FILIAL <= '" + _cFilAte + "' "
_cQuery  += " AND RA_CC >= '" + _cCcDe + "' AND RA_CC <= '" + _cCcAte + "' "
_cQuery  += " AND RA_MAT >= '" + _cMatDe + "' AND RA_MAT <= '" + _cMatAte + "' "
_cQuery  += " AND RA_ADMISSA <= '" + _cAdm + "' "
_cQuery  += " AND RG2_FILIAL >= '" + _cFilDe + "' AND RG2_FILIAL <= '" + _cFilAte + "' "
_cQuery  += " AND RG2_TPBEN IN(" + _cQryAux + ") "
_cQuery  += " AND RG2_PERIOD = '" + _cPeriodo + "' "
_cQuery  += " AND RA_DEMISSA = ' ' "

If _nOrd == 1

	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_MAT "

ElseIf _nOrd == 2

	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_CC "

ElseIf _nOrd == 3

	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_NOME "

Else

	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_MAT "

EndIf

//Verifica Tabela Aberta
If Select("QD03VB") > 0
	DBSelectArea("QD03VB")
	DBCloseArea()
EndIf

//Abrir Tabela
DbUseArea( .T., "TOPCONN", TcGenQry( ,, _cQuery), "QD03VB", .T., .F.)

If QD03VB->(Eof()) .And. QD03VB->(Bof())

	DBSelectArea("QD03VB")
	DBCloseArea()
    _cQuery:=RQuerySR0()

    //Abrir Tabela
    DbUseArea( .T., "TOPCONN", TcGenQry( ,, _cQuery), "QD03VB", .T., .F.)
    
EndIf

//Atualiza regua
DBGoTop()
nConta:=0
COUNT TO nConta
_oProcess:SetRegua2(nConta)

//-Transforma campos em Numerico e/ou Data
_aSraStruct := SRA->(dbStruct())

For _nAux := 1 To Len(_aSraStruct)

	If ( _aSraStruct[_nAux][2] <> "C" )

		TCSetField("QD03VB",_aSraStruct[_nAux][1],_aSraStruct[_nAux][2],_aSraStruct[_nAux][3],_aSraStruct[_nAux][4])

	EndIf

Next _nAux

QD03VB->(DBGoTop())

_cMyChave := ""
_nCount   := 0

While QD03VB->(!Eof())

	//Incrementa Régua
	_oProcess:IncRegua2("Fase 01 - "+ AllTrim(QD03VB->RA_NOME))

	//-Gera apenas 1 linha por funcionario
	If QD03VB->(RA_FILIAL+RA_MAT) == _cMyChave

		QD03VB->(DBSkip())
		Loop

	Else

		_cMyChave := QD03VB->(RA_FILIAL+RA_MAT)

	EndIf
	
	//Separa Numero do Endereco
 	//Caso nao tenha sido possivel separar o numero do endereco
 	//os conteudos serão preenchidos por serem obrigatorios no layout

	_cSRA_End := ''
	_cSRA_Num := ''

	If (_nPos := Rat(",",QD03VB->RA_ENDEREC)) > 0

		_cSRA_End := SubStr(QD03VB->RA_ENDEREC,1,_nPos - 1)
		_cSRA_Num := SubStr(QD03VB->RA_ENDEREC,_nPos + 1)

	EndIf
	
	If Empty(_cSRA_End)
    
    	_cSRA_End := QD03VB->RA_ENDEREC
    	_cSRA_Num := "0"
  
  	EndIf

	//-Busca a Sequencia do Endereco
	_nPosEnd := aScan(_aSeqEnd, {|x| x[1]==QD03VB->RA_LOCBNF })
	_nSeqEnd := _aSeqEnd[_nPosEnd,02]
	
	//Grava Detalhes Funcionario
	_nTotRegTP2++
	_nseq++
	FWrite( _nHdl, RHGeraLinhas( _aStruct[2], "02" ) )
	
	_nLin += 1	//-Indica que pode imprimir o Relatorio Final
	
	//Totaliza Registros
	_nTotal += _nVlr
	
	QD03VB->(DBSkip())
	
EndDo


_oProcess:SetRegua2(nConta)
//-------------------------------------------------------------------------------------//
// Codigo 3 - Beneficios                                                               //
//-------------------------------------------------------------------------------------//
QD03VB->(DBGoTop())
_oProcess:IncRegua1("Beneficios")

_cMyChave := ""
_nCount   := 0
_nTotRegTP3 := 0

While QD03VB->(!Eof())

	//Incrementa Régua
	_oProcess:IncRegua2("Fase 02 - "+ AllTrim(QD03VB->RA_NOME))

	//Grava Beneficios
	_nTotRegTP3++
	_nseq++
	
	FWrite( _nHdl, RHGeraLinhas( _aStruct[2], "03" ) )
	
	_nLin += 1	//-Indica que pode imprimir o Relatorio Final
	
	//Totaliza Registros
	_nTotal += _nVlr
	
	//IncProc("Processando...")
	QD03VB->(DBSkip())
	
EndDo	
	
	

//-------------------------------------------------------------------------------------//
// Codigo 4 - Residencia	dos Funcionarios	                                       //
//-------------------------------------------------------------------------------------//
_oProcess:SetRegua2(nConta)

_nTotRegTP4 := 0
_cMyChave := ""
QD03VB->( DBGoTop())
_oProcess:IncRegua1("Enderecos Funcionarios")

While QD03VB->(!Eof())

	
	//Incrementa Régua
	_oProcess:IncRegua2("Fase 03 - "+ AllTrim(QD03VB->RA_NOME))
	
	//-Gera apenas 1 linha por funcionario
	If QD03VB->(RA_FILIAL+RA_MAT) == _cMyChave
		QD03VB->(DBSkip())
		Loop
	Else
		_cMyChave := QD03VB->(RA_FILIAL+RA_MAT)
	EndIf

	//Grava 
	_nTotRegTP4++
	_nseq++
	
	FWrite( _nHdl, RHGeraLinhas( _aStruct[2], "04" ) )
	
	QD03VB->(DBSkip())
	
EndDo

//-------------------------------------------------------------------------------------//
// Codigo 5 - Detalhes adicionais dos Funcionarios	                                       //
//-------------------------------------------------------------------------------------//
_nTotRegTP5 := 0
_nQtdTotItem := 0
_nVlrTotItem := 0
_cMyChave := ""
_oProcess:SetRegua2(nConta)

QD03VB->( DBGoTop())
_oProcess:IncRegua1("Detalhes adicionais")

While QD03VB->(!Eof())

	//Incrementa Régua
	_oProcess:IncRegua2("Fase 04 - "+ AllTrim(QD03VB->RA_NOME))
	
	
	//-Gera apenas 1 linha por funcionario
	If QD03VB->(RA_FILIAL+RA_MAT) == _cMyChave
		QD03VB->(DBSkip())
		Loop
	Else
		_cMyChave := QD03VB->(RA_FILIAL+RA_MAT)
	EndIf

	//Grava 
	_nTotRegTP5++
	_nseq++

	FWrite( _nHdl, RHGeraLinhas( _aStruct[2], "05" ) )
	
	QD03VB->(DBSkip())
	
EndDo

//-------------------------------------------------------------------------------------//
// Codigo 9 - Trailler do Arquivo				                                       //
//-------------------------------------------------------------------------------------//
_nTotReg := _nseq + 1
_oProcess:IncRegua1("Trailer de arquivo")

_nseq    += 1
FWrite( _nHdl, RHGeraLinhas( _aStruct[3] ) )

_oProcess:SaveLog("Fim de processamento")    

Return

/*
===============================================================================================================================
Programa----------: MGPE014FI
Autor-------------: Josué Danich Prestes
Data da Criacao---: 22/01/2016
Descrição---------: Funções Diversas de relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE014FI()

Private _cString  := '' // Alias do Arquivo Principal
Private _aOrd     := {""}
Private aReturn  := { "Especial", 1, "Administracao", 1, 2, 2,'',1 }  
Private _nTamanho := 'P'
Private nLastKey := 0
Private m_pag    := 0
Private lEnd     := .F.
Private wnrel    := 'MGPE014'

//Envia controle para a funcao SETPRINT
wnrel := SetPrint(_cString,wnrel,"",'LISTAGEM DE BENEFICIOS','Emissao de Relatorio para avaliacao de Benefícios. ','Sera impresso de acordo com os parametros solicitados. ',,.F.,_aOrd,.F.,_nTamanho) 

If nLastKey == 27
	Return
EndIf

SetDefault(aReturn,_cString)

If nLastKey == 27
	Return
EndIf

//Processa Impressao
RptStatus({|lEnd| MGPE014RB()},'Imprimindo...') 
Return

/*
===============================================================================================================================
Programa----------: MGPE014RB
Autor-------------: Josué Danich Prestes
Data da Criacao---: 22/01/2016
Descrição---------: Relatório de beneficios
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE014RB()

Local _cFilialAnt    := ''
Local _cCcAnt        := ''
Local _nTfunc        := 0
Local _nTccFunc      := 0
Local _nTFlFunc      := 0
Local _nTBen         := 0
Local _nTccBen       := 0
Local _nTFlBen       := 0
Local cTitulo  :="INTEGRACAO DE BENEFICIOS COM EMPRESA SE SERVICOS"
Local cCabec1  :="FIL" + Space(1) + "Matric" + Space(2) + "Nome" + Space(Len(QD03VB->RA_NOME)-4+10) + "TP" + Space(9) +"Valor"
Local cCabec2  :=""
Local cNomeProg:="MGPE014"
Local cTamanho :="P"

// Posiciona Regitro
DBSelectArea("QD03VB")
QD03VB->(DBGoTop())

//Set Regua
SetRegua(nConta)

Cabec(cTitulo,cCabec1,cCabec2,cNomeProg,cTamanho,If(aReturn[4]==1,15,18)) 
nLin := 7

//Se Ordem Centro de Custo Imprime Nome Centro de Custo
If _nOrd == 2

	DBSelectArea("CTT")
	DBSetOrder(1)	//-CTT_FILIAL+CTT_CUSTO
	DBSeek(xFilial("CTT")+QD03VB->RA_CC,.F.)
	
	cDet := Space(5) + AllTrim(QD03VB->RA_CC) + " - " + CTT->CTT_DESC01
    @nLin,00 PSAY cDet
     nLin++ 
	//	Impr(cDet)//,'C'

EndIf

//Carrega Filial
_cFilialAnt := QD03VB->RG2_FILIAL



While !QD03VB->(Eof())

	//Abortado Pelo Operador
	If lAbortPrint
		cDet := '*** ABORTADO PELO OPERADOR ***' 
		Impr(cDet,'C')
		Exit
	EndIf

    If nLin > 60 
       Cabec(cTitulo,cCabec1,cCabec2,cNomeProg,cTamanho,If(aReturn[4]==1,15,18)) 
       nLin := 7
    EndIf    	

	_nVlr:= QD03VB->RG2_VALCAL
	cDet := QD03VB->RG2_FILIAL + Space(2) + QD03VB->RG2_MAT + Space(2) + QD03VB->RA_NOME + Space(10) + QD03VB->RG2_TPBEN + Space(9) +Transform(_nVlr,'@E 999,999.99')
    @nLin,00 PSAY cDet
     nLin++ 
	//	Impr(cDet)//,'C'
	
	QD03VB->(DBSkip())
	
	IncRegua("Imprimindo Mat.: "+QD03VB->RG2_MAT)
	
	//Totaliza
	_nTfunc   += 1
	_nTccFunc += 1
	_nTFlFunc += 1
	_nTBen    += _nVlr
	_nTccBen  += _nVlr
	_nTFlBen  += _nVlr
	
	If _nOrd == 2

		If _cCcAnt != QD03VB->RA_CC .Or. _cFilialAnt != QD03VB->RG2_FILIAL
			_cCcAnt := QD03VB->RA_CC
			
			cDet := 'Valores Totais Centro de Custo: ' + Space(10) + Transform(_nTccBen,'@E 999,999,999.99') 
            @nLin,00 PSAY cDet//Impr(cDet,'C')
             nLin++ 
			
			cDet := 'Quantidade de lançamentos Centro Custo: ' + Space(10)  + Transform(_nTccFunc, '@E 9,999') 
            @nLin,00 PSAY cDet//			Impr(cDet,'C')
             nLin++ 
             nLin++ 
			
			_nTccFunc := 0
			_nTccBen  := 0
			
			If !QD03VB->(Eof()) .And. _cFilialAnt == QD03VB->RG2_FILIAL

				DBSelectArea("CTT")
				DBSetOrder(1)	//-CTT_FILIAL+CTT_CUSTO
				DBSeek(xFilial("CTT")+QD03VB->RA_CC,.F.)
			
				cDet := Space(5) + AllTrim(QD03VB->RA_CC) + " - " + CTT->CTT_DESC01
                @nLin,00 PSAY cDet//				Impr(cDet,'C')
                 nLin++ 

			EndIf
			
		EndIf

	EndIf
	
	If _cFilialAnt != QD03VB->RG2_FILIAL

		_cFilialAnt := QD03VB->RG2_FILIAL
		
		cDet := 'Valores Totais da Filial: ' + Space(10) + Transform(_nTFlBen,'@E 999,999,999.99') 
        @nLin,00 PSAY cDet//		Impr(cDet,'C')
         nLin++ 
		
		cDet := 'Quantidade de lancamentos da Filial: ' + Transform(_nTFlFunc, '@E 9,999') 
        @nLin,00 PSAY cDet//		Impr(cDet,'C')
         nLin++ 
         nLin++ 
		
	    If !QD03VB->(Eof())
		   //Salta Página
           Cabec(cTitulo,cCabec1,cCabec2,cNomeProg,cTamanho,If(aReturn[4]==1,15,18)) 
           nLin := 7
        EndIf   
		
		_nTFlFunc := 0
		_nTFlBen  := 0
		
	    If _nOrd == 2 .And. !QD03VB->(Eof())

			DBSelectArea("CTT")
			DBSetOrder(1)	//-CTT_FILIAL+CTT_CUSTO
			DBSeek(xFilial("CTT")+QD03VB->RA_CC,.F.)
			
			cDet := Space(5) + AllTrim(QD03VB->RA_CC) + " - " + CTT->CTT_DESC01
            @nLin,00 PSAY cDet//			Impr(cDet,'C')
             nLin++ 

		EndIf
		
	EndIf
	
EndDo

 nLin++ 
 cDet := 'Valores Totais da Empresa: ' + Space(30) + Transform(_nTBen,'@E 999,999,999.99') 
@nLin,00 PSAY cDet//Impr(cDet,'C')
 nLin++ 
 cDet := 'Quantidade de lançamentos da Empresa: ' + Transform(_nTfunc, '@E 9,999') 
@nLin,00 PSAY cDet//Impr(cDet,'C')
 nLin++ 

cDet := ''
Impr(cDet,'F')

If aReturn[5] == 1
	Set Printer to
	Ourspool(wnrel)
EndIf

MS_FLUSH()

Return

/*
===============================================================================================================================
Programa----------: MGPE014CO
Autor-------------: Josué Danich Prestes
Data da Criacao---: 22/01/2016
Descrição---------: Consulta de tipo de beneficios
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE014CO()

Local _MvPar		:= ""
Local _MvParDef 	:= ""
Local _aItens   	:= {}
Local _aArea    	:= FWGetArea()

_MvPar := &(AllTrim(ReadVar()))       // Carrega Nome da Variavel do Get em Questao
_MvRet := AllTrim(ReadVar())          // Iguala Nome da Variavel ao Nome variavel de Retorno

DBSelectArea("RCC")
DBSetOrder(1)
DBSeek(xFilial("RCC")+"S011")

While !Eof() .And. RCC->RCC_FILIAL + RCC->RCC_CODIGO == xFilial("RCC")+"S011"
	
	If SubStr(RCC->RCC_CONTEU,33,3) == AllTrim(MV_PAR01)

		aAdd(_aItens, SubStr(RCC->RCC_CONTEU,3,30))
		_MvParDef += SubStr(RCC->RCC_CONTEU,1,2)

	EndIf
	
	("RCC")->(DBSkip())

End

//         Retorno,Titulo,opcoes,Strin Ret,lin,col, Tipo Sel,tam chave , n. ele ret, Botao
If f_Opcoes(@_MvPar, "Opções", _aItens, _MvParDef, 12, 49, .F., 2) 

	&_MvRet := _MvPar                                      // Devolve Resultado

EndIf

FWRestArea(_aArea)                                  // Retorna Alias

Return .T.

/*
===============================================================================================================================
Programa----------: RQuerySR0()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/10/2019
Descrição---------: Consulta de tipo de beneficios
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RQuerySR0()
Local _cQuery  := "SELECT " 
_cQuery  += " R0_FILIAL  RG2_FILIAL,"
_cQuery  += " R0_VALCAL  RG2_VALCAL,"  
_cQuery  += " R0_MAT     RG2_MAT,"  
_cQuery  += " R0_TPVALE  RG2_TPBEN,"  
_cQuery  += " R0_DIASPRO-R0_FALTAS RG2_DUTILM ,"  
_cQuery  += " R0_CODIGO  RG2_CODIGO,"  
_cQuery  += " R0_QDIAINF RG2_VTDUTE,"  

_cQuery  += " RA_FILIAL,"
_cQuery  += " RA_CC,"
_cQuery  += " RA_MAT,"
_cQuery  += " RA_NOME,"
_cQuery  += " RA_ADMISSA,"
_cQuery  += " RA_DEMISSA,"
_cQuery  += " RA_LOCBNF,"
_cQuery  += " RA_ENDEREC,"
_cQuery  += " RA_COMPLEM,"
_cQuery  += " RA_BAIRRO,"
_cQuery  += " RA_MUNICIP,"
_cQuery  += " RA_ESTADO,"
_cQuery  += " RA_ESTADO,"
_cQuery  += " RA_CEP,"
_cQuery  += " RA_TELEFON,"
_cQuery  += " RA_NASC,"
_cQuery  += " RA_CIC,"
_cQuery  += " RA_RG,"
_cQuery  += " RA_MAE,"
_cQuery  += " RA_EMAIL,"
_cQuery  += " RA_ESTCIVI,"
_cQuery  += " RA_SEXO,"
_cQuery  += " RA_PAI,"
_cQuery  += " RA_RGUF,"
_cQuery  += " RA_LOGRNUM,"
_cQuery  += " RA_LOGRDSC "

_cQuery  += " FROM " + RetSqlName("SR0") + " SR0 "
_cQuery  += " INNER JOIN " + RetSqlName("SRA") + " SRA "
_cQuery  += " ON SRA.RA_MAT = SR0.R0_MAT AND SRA.RA_FILIAL = SR0.R0_FILIAL "

_cQuery  += " WHERE "
_cQuery  += " SRA.D_E_L_E_T_ = ' ' AND SR0.D_E_L_E_T_ = ' ' "
_cQuery  += " AND RA_FILIAL >= '" + _cFilDe + "' AND RA_FILIAL <= '" + _cFilAte + "' "
_cQuery  += " AND RA_CC >= '" + _cCcDe + "' AND RA_CC <= '" + _cCcAte + "' "
_cQuery  += " AND RA_MAT >= '" + _cMatDe + "' AND RA_MAT <= '" + _cMatAte + "' "
_cQuery  += " AND RA_ADMISSA <= '" + _cAdm + "' "
_cQuery  += " AND R0_FILIAL >= '" + _cFilDe + "' AND R0_FILIAL <= '" + _cFilAte + "' "
_cQuery  += " AND R0_TPVALE = '0' AND R0_VALCAL > 0 "
_cQuery  += " AND RA_DEMISSA = ' ' "

If _nOrd == 1
	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_MAT "
ElseIf _nOrd == 2
	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_CC "
ElseIf _nOrd == 3
	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_NOME "
Else
	_cQuery  += " ORDER BY SRA.RA_FILIAL,SRA.RA_MAT "
EndIf

Return _cQuery
