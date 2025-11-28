/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |30/07/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |21/07/2021| Chamado 37147. Tratamento para produtores familiares (A2_L_CLASS=L)
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "REPORT.CH"

/*
===============================================================================================================================
Programa--------: RGLT039
Autor-----------: Fabiano Dias
Data da Criacao-: 21/12/2009
Descrição-------: Relatorio que trara os fornecedores por setor e classificado que estao inativos
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT039

Local   oSetor		:= Nil
Local   oQbrClassf	:= Nil
Local   oProdutores	:= Nil

Private oReport		:= Nil
Private cPerg   	:= "RGLT039"

Pergunte(cPerg,.F.)

oReport := TReport():New(cPerg,"Relação de Produtores desativados",cPerg,{|oReport| PrintReport(oReport)},"Este relatório ira imprimir a relação de produtores por setor e classifição que nao estão ativos.")

//================================================================================
//| Configuração dos modos de Impressao                                          |
//================================================================================
oReport:SetPortrait()
oReport:SetTotalInLine(.F.)

//================================================================================
//| Definção da secao - setor e tipo classif. do produtor                        |
//================================================================================
DEFINE Section oSetor				OF oReport					TITLE "Setor" TABLES "ZL3","SA2","ZL2"
oSetor:SetBorder("TOP",2)

DEFINE CELL NAME "ZL3_SETOR"		OF oSetor ALIAS "ZL3"		TITLE "Código"
DEFINE CELL NAME "ZL2_DESCRI"		OF oSetor ALIAS "ZL2"		TITLE "Setor"  
DEFINE CELL NAME "CLASSIFICACAO"	OF oSetor ALIAS ""			TITLE "Classif. Produtor"

//================================================================================
//| Definição da secao - dados do produtor                                       |
//================================================================================
DEFINE Section oProdutores			OF oSetor					TITLE "Produtores" TABLES "SA2"
oProdutores:SetBorder("TOP",2)

DEFINE CELL NAME "A2_COD"			OF oProdutores ALIAS "SA2"	TITLE "Código"
DEFINE CELL NAME "A2_LOJA"			OF oProdutores ALIAS "SA2"	TITLE "Loja"
DEFINE CELL NAME "A2_NOME"			OF oProdutores ALIAS "SA2"	TITLE "Produtor"
DEFINE CELL NAME "CGC"				OF oProdutores ALIAS ""		TITLE "CPF/CNPJ" SIZE 16
DEFINE CELL NAME "A2_L_SIGSI"		OF oProdutores ALIAS "SA2"	TITLE "SIGSIF"
DEFINE CELL NAME "ZL3_COD"			OF oProdutores ALIAS "ZL3"	TITLE "Linha/Rota"
DEFINE CELL NAME "ZL3_DESCRI"		OF oProdutores ALIAS "ZL3"	TITLE "Descrição"

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
oQbrClassf	:= TRBreak():New( oSetor	, oSetor:CELL("ZL3_SETOR") , "TOTAL DE PRODUTORES - CLASSIFICACAO"	, .F. )
oQbrSetor	:= TRBreak():New( oReport	, oSetor:CELL("ZL3_SETOR") , "TOTAL DE PRODUTORES - SETOR"			, .F. )

//================================================================================
//| Configuração dos totalizadores                                               |
//================================================================================
TRFunction():New( oProdutores:Cell("A2_COD") , NIL , "COUNT" , oQbrClassf	, NIL , NIL , NIL , .F. , .F. ) //Totalizador por Classificacao
TRFunction():New( oProdutores:Cell("A2_COD") , NIL , "COUNT" , oQbrSetor	, NIL , NIL , NIL , .F. , .T. ) //Totalizador por Setor

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: PrintReport
Autor-------------: Fabiano Dias
Data da Criacao---: 21/12/2009
Descrição---------: Processamento do Relatorio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PrintReport(oReport)

Local _cAlias	:= ""
Local _cFiltro	:= "%"
Local _nCountRec	:= 0

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND SA2.A2_L_DTDES = '" + StrZero( Month( MV_PAR01 ) , 2 ) + AllTrim( Str( Year( MV_PAR01 ) ) ) + "'"

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR07) .Or. Empty(MV_PAR07) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL3.ZL3_SETOR IN "+ FormatIn( AllTrim(MV_PAR07) , ';' )
EndIf

If !Empty(MV_PAR08)
	_cFiltro += " AND SA2.A2_L_CLASS IN " + FormatIn( AllTrim(MV_PAR08) , ";" )
EndIf

If !Empty(MV_PAR09)
	_cFiltro += " AND ZL3.ZL3_COD IN " + FormatIn( MV_PAR09 , ";" )
EndIf

_cFiltro += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

   	BeginSql alias _cAlias
		SELECT SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_CGC, SA2.A2_L_SIGSI,
		       Case
		         WHEN SA2.A2_L_CLASS = 'I' THEN
		          'INDIVIDUAL'
		         WHEN SA2.A2_L_CLASS = 'C' THEN
		          'COLETIVO'
		         WHEN SA2.A2_L_CLASS = 'U' THEN
		          'USUARIO TC'
				 WHEN SA2.A2_L_CLASS = 'F' AND SA2.A2_L_TANQ = SA2.A2_COD AND SA2.A2_L_TANLJ = SA2.A2_LOJA THEN
		          'RESP. FAMILIAR'
				 WHEN SA2.A2_L_CLASS = 'F' AND (SA2.A2_L_TANQ <> SA2.A2_COD OR SA2.A2_L_TANLJ = SA2.A2_LOJA) THEN
		          'USR. FAMILIAR'
		         Else
		          'SEM CLAS.'
		       END CLASSIFICACAO,
		       ZL3.ZL3_COD, ZL3.ZL3_DESCRI, ZL3.ZL3_SETOR, ZL2.ZL2_DESCRI
		  FROM %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:ZL2% ZL2
		 WHERE SA2.D_E_L_E_T_ = ' '
		   AND ZL2.D_E_L_E_T_ = ' '
		   AND ZL3.D_E_L_E_T_ = ' '
		   AND SA2.A2_FILIAL = %xFilial:SA2%
		   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
		   AND ZL2.ZL2_FILIAL = %xFilial:ZL2%
		   AND SA2.A2_L_LI_RO = ZL3.ZL3_COD
		   AND ZL3.ZL3_SETOR = ZL2.ZL2_COD
		   AND SA2.A2_COD LIKE 'P%'
		   AND SA2.A2_L_ATIVO = 'N'
		   %exp:_cFiltro%
		   AND SA2.A2_COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
		   AND SA2.A2_LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
		 ORDER BY ZL3.ZL3_SETOR, CLASSIFICACAO, ZL3.ZL3_COD, SA2.A2_COD, SA2.A2_LOJA
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

Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

//================================================================================
//Define a relação e o agrupamento do conteúdo
//================================================================================
oReport:Section(1):Section(1):SetParentQuery()
oReport:Section(1):Section(1):SetParentFilter( {|cParam| (_cAlias)->( ZL3_SETOR + CLASSIFICACAO ) == cParam } , {|| (_cAlias)->( ZL3_SETOR + CLASSIFICACAO ) } )
	
//================================================================================
//Chama o processamento da impressão do Relatório
//================================================================================
oReport:Section(1):Section(1):Cell("CGC"):SetBlock( { || Transform((_cAlias)->A2_CGC, IIf(Len(AllTrim((_cAlias)->A2_CGC))>11,"@R! NN.NNN.NNN/NNNN-99","@R 999.999.999-99")) } )
oReport:Section(1):Print(.T.)

(_cAlias)->(DBCloseArea())

Return
