/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |09/01/2014| Chamado 8049. Ajustes no relatório para não dar erro nas chamadas da rotina AGLT012 quando não 
              |          | encontrar registros para imprimir.
Lucas Borges  |27/03/2019| Chamado 11132. Ajuste para imprimir empréstimos do Leite de Terceiros.
Lucas Borges  |14/05/2019| Chamado 29246. Ajuste no layout do relatório.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT030
Autor-------------: Italac
Data da Criacao---: 21/05/2009
Descrição---------: Relação de Empréstimos e Adiantamentos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT030( aParam )

Local cDesc1	:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2	:= "de acordo com os parametros informados pelo usuario."
Local cDesc3	:= ""
Local titulo	:= "RELACAO DE EMPRESTIMOS E ADIANTAMENTOS"
Local nLin		:= 80
Local Cabec1	:= ""
Local Cabec2	:= ""
Local aOrd		:= {}

Private _nTp		:= IIf(FUNNAME() == "AGLT012",1,2)//1-Próprio 2-Terceiros
Private lAbortPrint	:= .F.
Private Tamanho		:= "G"
Private NomeProg	:= "RGLT030" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo		:= 18
Private aReturn		:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey	:= 0
Private m_pag		:= 01
Private wnrel		:= "RGLT030" // Coloque aqui o nome do arquivo usado para impressao em disco
Private aDados		:= aParam // Dados dos emprestimos
Private cString		:= IIf(_nTp==1,"ZLM","ZLN")

If _nTp == 1
	Cabec1	:= "CODIGO    SETOR               FORNECEDOR                            VALOR TOTAL QTD.PARC.     JUROS VLR.PARCELA     PRODUCAO*    PGTO.LIQ.**     DATA 1o. VENC.     DATA CREDITO    OBS. "
Else
	Cabec1	:= "CODIGO      FORNECEDOR                            VALOR TOTAL QTD.PARC.    JUROS   VLR.PARCELA      DATA 1o. VENC.     DATA CREDITO    OBS. "
EndIf

DBSelectArea(cString)
(cString)->( DBSetOrder(1) )

wnrel := SetPrint( cString , NomeProg , "" , @titulo , cDesc1 , cDesc2 , cDesc3 , .T. , aOrd , .T. , Tamanho ,, .T. )

If nLastKey == 27
	Return
EndIf

SetDefault( aReturn , cString )

If nLastKey == 27
   Return
EndIf

nTipo := If( aReturn[4] == 1 , 15 , 18 )

//================================================================================
// Processamento. RPTSTATUS monta janela com a regua de processamento.
//================================================================================
RptStatus( {|| RunReport( Cabec1 , Cabec2 , Titulo , nLin ) } , Titulo )

Return

/*
===============================================================================================================================
Programa----------: RUNREPORT
Autor-------------: Italac
Data da Criacao---: 21/05/2009
Descrição---------: Função para controle do processamento do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RunReport( Cabec1 , Cabec2 , Titulo , nLin )

Local nTotVlrTot	:= 0
Local _nI			:= 0

DBSelectArea(cString)
(cString)->( DBSetOrder(1) )

//================================================================================
// SETREGUA -> Indica quantos registros serao processados para a regua
//================================================================================
SetRegua( Len( aDados ) )

For _nI := 1 to Len(aDados)

	//================================================================================
	// Verifica o cancelamento pelo usuario.
	//================================================================================
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	EndIf
	
	//================================================================================
	// Impressao do cabecalho do relatorio - Salto de Página. Formulario = 55 linhas
	//================================================================================
	If nLin > 55
		Cabec( Titulo , Cabec1 , Cabec2 , NomeProg , Tamanho , nTipo )
		nLin := 8
	EndIf
	
	@ nLin , 000 PSAY aDados[_nI][02]																// Codigo
	If _nTp == 1
		@ nLin , 010 PSAY IIf(_nTp==1,LEFT( aDados[_nI][03] , 19 ),"")										// Setor
	EndIf
	@ nLin , IIf(_nTp==1,030,012) PSAY LEFT( aDados[_nI][IIf(_nTp==1,11,08)] +'/'+ aDados[_nI][IIf(_nTp==1,12,09)] +' - '+ aDados[_nI][IIf(_nTp==1,04,03)] , 38 )	// Nome
	@ nLin , IIf(_nTp==1,066,048) PSAY Transform( aDados[_nI][IIf(_nTp==1,05,04)] , "@E 999,999,999.99"	)							// Total Solicitado
	@ nLin , IIf(_nTp==1,081,065) PSAY Transform( aDados[_nI][IIf(_nTp==1,06,05)] , "@E 999"				)							// Qtd Parcela
	@ nLin , IIf(_nTp==1,091,072) PSAY Transform( aDados[_nI][IIf(_nTp==1,07,06)] , "@E 99.999999"		)							// Juros
	@ nLin , IIf(_nTp==1,103,085) PSAY Transform( aDados[_nI][IIf(_nTp==1,08,07)] , "@E 999,999.99"		)							// Vlr Parcela
	If _nTp == 1
		@ nLin , 114 PSAY IIf(_nTp==1,Transform( aDados[_nI][09] , "@E 999,999,999"		),"")							// Producao
		@ nLin , 127 PSAY IIf(_nTp==1,Transform( aDados[_nI][10] , "@E 999,999,999.99"	),"")							// Faturamento
	EndIf
	@ nLin , IIf(_nTp==1,146,102) PSAY DToC( SToD( aDados[_nI][IIf(_nTp==1,13,10)] ) )												// Data do 1 vencimento
	@ nLin , IIf(_nTp==1,165,120) PSAY DToC( SToD( aDados[_nI][IIf(_nTp==1,14,11)] ) )												// Data do credito
	@ nLin , IIf(_nTp==1,181,137) PSAY aDados[_nI][IIf(_nTp==1,15,12)]																// Obs
	
	//================================================================================
	// Totalizador
	//================================================================================
	nTotVlrTot += aDados[_nI][IIf(_nTp==1,05,04)]
	
	nLin++
	
	@ nLin , 000 PSAY __PrtThinLine()
	
	nLin++
	nLin++

Next _nI

nLin--

@ nLin , 000 PSAY 'TOTAL'
@ nLin , IIf(_nTp==1,065,047) PSAY Transform( nTotVlrTot , "@E 999,999,999.99" ) // Total Solicitado

nLin += 6

@ nLin , 050 psay "[___] Aprovado  [___] Reprovado"

nLin += 2

@ nLin , 010 psay Replicate("_",30)
@ nLin , 050 psay Replicate("_",30)

nLin++

@ nLin , 010 psay "Gerente"
@ nLin , 050 psay "Diretor"

nLin:=50

If _nTp == 1
	@ nLin , 000 psay "*  Volume medio dos ultimos tres meses."
	
	nLin++
	
	@ nLin , 000 psay "** Media dos ultimos tres meses da Remuneracao liquida do Fornecedor."
EndIf
//================================================================================
// Finaliza a execucao do relatorio.
//================================================================================
SET DEVICE TO SCREEN

//================================================================================
// Se impressao For em disco, chama o gerenciador de impressao.
//================================================================================
If aReturn[5] == 1

   DBCommitAll()
   SET PRINTER TO
   OurSpool(wnrel)
   
EndIf

MS_FLUSH()

Return
