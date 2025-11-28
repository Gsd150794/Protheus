/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/09/2022| Chamado 41230. Incluídos estados tratados pelo método NfeConsultaCadastro
Lucas Borges  |04/10/2022| Chamado 41447. Corrigir caracter indevido inserido por esse teclado lixo
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT059
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 06/12/2018
Descrição---------: Realiza consulta na SEFAZ sobre a situação cadastral do Produtor e lista Inativos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT059()

Local oReport
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 06/12/2018
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oFornece

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT059","Situação Inscrição Estadual SEFAZ","RGLT059",; 
{|oReport| ReportPrint(oReport)},"Verifica situação das Inscrições Estaduais dos Fornecedores junto à SEFAZ")

Pergunte("RGLT059",.F.)
oReport:SetTotalInLine(.F.)

//=======================================================================
//Criacao da secao utilizada pelo relatorio
//TRSection():New
//ExpO1 : Objeto TReport que a secao pertence
//ExpC2 : Descricao da seçao
//ExpA3 : Array com as tabelas utilizadas pela secao. A primeira tabela
//			sera considerada como principal para a seção.
//ExpA4 : Array com as Ordens do relatório
//ExpL5 : Carrega campos do SX3 como celulas
//			Default : False
//ExpL6 : Carrega ordens do Sindex
//			Default : False
//=======================================================================
//=======================================================================
//Criacao da celulas da secao do relatorio
//TRCell():New
//ExpO1 : Objeto TSection que a secao pertence
//ExpC2 : Nome da celula do relatório. O SX3 será consultado
//ExpC3 : Nome da tabela de referencia da celula
//ExpC4 : Titulo da celula
//			Default : X3Titulo()
//ExpC5 : Picture
//			Default : X3_PICTURE
//ExpC6 : Tamanho
//			Default : X3_TAMANHO
//ExpL7 : Informe se o tamanho esta em pixel
//			Default : False
//ExpB8 : Bloco de código para impressao.
//			Default : ExpC2
//=======================================================================

//Secao 1 - Fornecedores
oFornece := TRSection():New(oReport,"Fornecedores",{"SA2"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
oFornece:SetTotalInLine(.F.)
//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oFornece,"ZLD_SETOR","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornece,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornece,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornece,"A2_NOME","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornece,"A2_INSCR","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornece,"A2_EST","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornece,"SITUACAO",/*cAlias*/,"Situação"/*cTitle*/,/*Picture*/,09/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornece,"A2_CGC","SA2",/*cTitle*/,"@R XXXXXXXXXXXXXXXX"/*Picture*/,18/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

//Totalizador de fornecedores com inconsistencia
TRFunction():New(oFornece:Cell("A2_COD"),NIL,"COUNT",/*oBreak*/,/*cTitulo*/,/*cPicture*/,/*uFormula*/,.T.,.F.)

Return(oReport)

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 06/12/2018
Descrição---------: A funcStaticatica ReportDef devera ser criada para todos os relatorios que poderao ser agendados pelo usuario.
Parametros--------: ExpO1: Objeto Report do Relatório
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport)

Local _cAlias 		:= ""
Local _cFiltro		:= "%"
Local _aSelFil		:= {}
Local _nCount 		:= 0
Local _lFirst 		:= .T.
Local _nCountRec	:= 0
Local _lSchedule	:= FWGetRunSchedule()
Local _cSituacao	:= "Erro"

//Chama função que permitirá a seleção das filiais
If MV_PAR07 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLD")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
oReport:Section(1):Cell("SITUACAO"):SetBlock({||_cSituacao })

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
If MV_PAR08 = 1
	_cFiltro += " AND ZLD_STATUS = 'F'"
EndIf
//Normalmente não precisaria desse filtro pois o fonte trataria o agendamento independente da filial, porém, se For informado apenas a empresa, ele irá processar
//e disparar e-mail para todas as filiais que nem usam o leite. Se informar todas as filiais que usam o leite, ele processará todos ao mesmo tempo, ocupando todas as threads.
//Diante disso, travei para que sempre sejam processadas todas as filiais ao mesmo tempo, bastando agendar uma filial qualquer.
If !_lSchedule
	_cFiltro+=" AND ZLD_FILIAL " +GetRngFil( _aSelFil, "ZLD", .T.,) +"%"
EndIf

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql Alias _cAlias
	SELECT A2_COD, A2_LOJA, A2_NOME, A2_EST, A2_INSCR, A2_CGC, ZLD_SETOR
	FROM %Table:ZLD% ZLD, %Table:SA2% SA2
	  WHERE SA2.D_E_L_E_T_ = ' '
		AND ZLD.D_E_L_E_T_ = ' '
		AND A2_COD = ZLD_RETIRO
		AND A2_LOJA = ZLD_RETILJ
		%Exp:_cFiltro%
		AND A2_COD BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
		AND A2_LOJA BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
		AND A2_EST IN ('AC','BA','CE','GO','MT','MS','MG','PB','PR','PE','RN','RS','SC','SP')
		AND ZLD_DTCOLE BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06% 
	GROUP BY A2_COD, A2_LOJA, A2_NOME, A2_EST, A2_INSCR, A2_CGC, ZLD_SETOR
	ORDER BY A2_COD, A2_LOJA
EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:Section(1):Init()
Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	_nCount++
	oReport:Section(1):Cell("A2_CGC"):SetBlock( { || Transform((_cAlias)->A2_CGC, IIf(Len(AllTrim((_cAlias)->A2_CGC))>11,"@R! NN.NNN.NNN/NNNN-99","@R 999.999.999-99")) } )

	If Mod(_nCount, 100) == 0
		Sleep(5000)//Aguarda 1 segundos para evitar sobrecarga do TSS
	EndIf

	//Verifico se possui possível inscrição válida. Do contário, não preciso consultar
	If Empty((_cAlias)->A2_INSCR) .Or. "ISENT" $ (_cAlias)->A2_INSCR
		_cSituacao := "Não consultar"
	Else
		_cSituacao := "Erro"
		ConsCad((_cAlias)->A2_INSCR,(_cAlias)->A2_EST,_lSchedule,@_cSituacao)
	EndIf
	//1-Irregular/ 2-Todos
	If MV_PAR09 == 2 .Or. (_cSituacao == "Erro" .Or. _cSituacao == "Irregular")
		If _lFirst
			oReport:Section(1):Init()
			_lFirst := .F.
		EndIf
		oReport:Section(1):PrintLine()
		oReport:IncMeter()
	EndIf

	(_cAlias)->(DBSkip())

EndDo
If !_lFirst
	oReport:Section(1):Finish()
EndIf

Return
/*
===============================================================================================================================
Programa----------: ConsCad
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 06/12/2018
Descrição---------: Realiza a consulta da situação cadastral do Fornecedor na SEFAZ
Parametros--------: cIE: Inscrição Estadual
					cUF: Estado
					_lSchedule: Executado via Schedule
Retorno-----------: _lRet: .T. - Situação Regular - .F. Situação Irregular
===============================================================================================================================
*/
Static Function ConsCad(cIE,cUF,_lSchedule,_cSituacao)

Local cURL		:= PadR(GetNewPar("MV_SPEDURL","http://"),250)
Local cIdEnt	:= "" 
Local nX		:= {}
Local _lRepetir	:= .T.
Local _nQtd		:= 0
Private oWs

cIdEnt := RetIdEnti()
oWs:= WsNFeSBra() :New()
oWs:cUserToken := "TOTVS"
oWs:cID_ENT := cIdEnt
oWs:cUF := cUF
oWs:cCNPJ := ""
oWs:cCPF := ""
oWs:cIE := AllTrim(cIE)
oWs:_URL := AllTrim(cURL)+"/NFeSBRA.apw"

While _lRepetir
	_nQtd++
	If oWs:CONSULTACONTRIBUINTE()
		If ( Len(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE) > 0 )
			nX := Len(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE)
			//1 - Habilitado 0 - Não Habilitado
			If oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cSituacao == '1'
				_cSituacao := "Regular"
			Else
				_cSituacao := "Irregular"
			EndIf
		  	_lRepetir:= .F.
		EndIf
	Else
		If _lSchedule .And. _nQtd > 2// Não realizar uma segunda tentativa quando For agendado
			_lRepetir:= .F.
		ElseIf !_lSchedule .And. !ApMsgYesNo("Não foi possivel realizar a consulta. Deseja fazer uma nova tentativa?","RGLT05901")
			_lRepetir:= .F.
			Sleep(5000)//Aguarda 5 segundos para testar novamente pois provavelmente sobrecarregou o TSS
		EndIf
	EndIf
EndDo				
Return

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
					No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro 
					das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
					mento do Schedule será verificado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
					metros com as informações do retorno da SchedDef(), deixando de verificar assim as informações na SXD. O 
					retorno da SchedDef deverá ser um array.
					Válido para Function e User Function, lembrando que uma vez definido a SchedDef, ao chamar a rotina o ambi-
					ente já está inicializado.
					Uma vez definido a Static Function SchedDef(), a rotina deixa de ser uma execução como processo especial, 
					ou seja, não se deve cadastrá-la no Agendamento passando parâmetros de linha. Ex: Funcao("A","B") ou 
					U_Funcao("A","B").
Parametros--------: aReturn[1] - Tipo: "P" - para Processo, "R" -  para Relatórios
					aReturn[2] - Nome do Pergunte, caso nao use passar ParamDef
					aReturn[3] - Alias  (para Relatório)
					aReturn[4] - Array de ordem  (para Relatório)
					aReturn[5] - Título (para Relatório)
Retorno-----------: aParam
===============================================================================================================================
*/
Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}

aParam := { "R",;
            "RGLT059",;
            "",;
            aOrd,;
            'Situação Inscrição Estadual SEFAZ'}

Return aParam
