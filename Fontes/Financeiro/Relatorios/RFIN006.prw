/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/08/2019| Chamado 30185. Modificada validação de acesso aos setores.
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |25/05/2021| Chamado 36623. Corrigido filtro de setor.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIN006
Autor-------------: Renato/Abrahao
Data da Criacao---: 15/10/2009
Descrição---------: Relacao de Titulos do Contas a Pagar (totaliza por Prefixo)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN006()

Local cDesc1			:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2			:= "de acordo com os parametros informados pelo usuario."
Local cDesc3			:= "Producao por Municipio"
Local titulo			:= "Contas a Pagar"
Local nLin				:= 80
Local Cabec1			:= "PRF NUMERO    PAR TP  FORNECEDOR                       EMISSAO    VENCTO     VALOR          SALDO"      
Local Cabec2			:= ""
Local aOrd				:= {}
Private Tamanho			:= "G"
Private NomeProg		:= "RFIN006" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo			:= 18
Private aReturn			:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey		:= 0
Private m_pag			:= 01
Private wnrel			:= "RFIN006" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cPerg			:= "RFIN006"
Private cString			:= "SE2"

Pergunte(cPerg,.F.)

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)
If nLastKey == 27
	Return
EndIf

SetDefault(aReturn,cString)
If nLastKey == 27
	Return
EndIf

nTipo := If(aReturn[4]==1,15,18)
RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return

/*
===============================================================================================================================
Programa----------: RFIN006
Autor-------------: Renato/Abrahao
Data da Criacao---: 09/12/2008
Descrição---------: Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS monta a janela com a regua de processamento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

Local _nTotValor	:=0
Local _cAlias		:= GetNextAlias()
Local _cFiltro		:= "%"
Local _cUltPrf		:=""
Private nSubValor	:=0

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu, não validar a ZLU pois o relatório é para tratar todos os títulos do financeiro, logo, um usuário que não
//possui qualquer vínculo com o Leite também poderá usar
If !Empty(MV_PAR15)
	_cFiltro += " AND E2_L_SETOR IN "+ FormatIn( AllTrim(MV_PAR15) , ';' )
EndIf
_cFiltro += "%"

BeginSql alias _cAlias
	SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCTO, E2_VALOR, E2_ACRESC, E2_DECRESC,
			E2_SALDO, E2_SDACRES, E2_SDDECRE
	  FROM %Table:SE2%
	 WHERE D_E_L_E_T_ = ' '
	   AND E2_FILIAL = %xFilial:SE2%
	   %exp:_cFiltro%
	   AND E2_PREFIXO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	   AND E2_NUM BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
	   AND E2_TIPO BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	   AND E2_EMISSAO BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
	   AND E2_VENCTO BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
	   AND E2_FORNECE BETWEEN %exp:MV_PAR11% AND %exp:MV_PAR13%
	   AND E2_LOJA BETWEEN %exp:MV_PAR12% AND %exp:MV_PAR14%
	 ORDER BY E2_PREFIXO, E2_NUM, E2_PARCELA
EndSql

COUNT To nqtdregs
setRegua(nqtdregs)

(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())

	IncRegua()
	
	If _cUltPrf != (_cAlias)->E2_PREFIXO .And. _cUltPrf != ""
		nLin:=ShowSubTotal(nLin)
	EndIf
	_cUltPrf:=(_cAlias)->E2_PREFIXO

    If nLin >= 50
   		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
   		nLin := 9
	EndIf
	
	@nLin,000 PSay (_cAlias)->E2_PREFIXO
	@nLin,004 PSay (_cAlias)->E2_NUM
	@nLin,014 PSay (_cAlias)->E2_PARCELA
	@nLin,018 PSay (_cAlias)->E2_TIPO
	@nLin,022 PSay (_cAlias)->E2_FORNECE
	@nLin,029 PSay (_cAlias)->E2_LOJA
	@nLin,034 PSay (_cAlias)->E2_NOMFOR
	@nLin,055 PSay DToC(SToD((_cAlias)->E2_EMISSAO))
	@nLin,066 PSay DToC(SToD((_cAlias)->E2_VENCTO))
	@nLin,077 PSay Transform((_cAlias)->(E2_VALOR+E2_ACRESC+E2_DECRESC),"@E 999,999,999.99")
	@nLin,092 PSay Transform((_cAlias)->(E2_SALDO+E2_SDACRES+E2_SDDECRE),"@E 999,999,999.99")
 	nLin++        
 	
 	_nTotValor += (_cAlias)->(E2_VALOR+E2_ACRESC+E2_DECRESC)
 	nSubValor += (_cAlias)->(E2_VALOR+E2_ACRESC+E2_DECRESC)
	
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

nLin:=ShowSubTotal(nLin)

nLin++
@nLin,000 PSay "Total Geral ------> "
@nLin,077 PSay Transform(_nTotValor,"@E 999,999,999.99")

	
SET DEVICE TO SCREEN
If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
EndIf
MS_FLUSH()

Return

/*
===============================================================================================================================
Programa----------: showSubTot
Autor-------------: Renato/Abrahao
Data da Criacao---: 10/15/09
Descrição---------: Mostra subtotal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ShowSubTotal(nlin)

@nLin,000 PSay "SubTotal do Prefixo ------->"
@nLin,077 PSay Transform(nSubValor,"@E 999,999,999.99")
nLin+=2

nSubValor:=0

Return nlin
