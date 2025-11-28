/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                          
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 27/07/2018 | Inclusão de cálculo por supervisor - Chamado 25555
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 04/01/2018 | Universalização da rotina para chamar do webservice - Chamado 27138 
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges  	  | 16/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
-------------------------------------------------------------------------------------------------------------------------------
 Jonathan     	  | 20/10/2020 | Ajuste novo percentual de comissão. Chamado 34310
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 18/11/2020 | Correção do calculo do campo C5_I_PSORI. Chamado 34736
-------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 21/01/2021 | Inclusão das comissões do novo Gerente Nacional. Chamado 35183.                              
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS013
Autor-------------: Renato de Morcerf
Data da Criacao---: 02/09/2008
===============================================================================================================================
Descrição---------: Localiza comissão de Vendedores e Supervisores - Chamado 8875
===============================================================================================================================
Parametros--------: _lcomp - compatibilidade
					_cvend - vendedor do pedido
					_ccliente - cliente do pedido
					_clojacli - loja do pedido
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS013(_lcomp,_cvend,_ccliente,_clojacli)

Local aArea	   := FWGetArea()
Local cQry1    := ""
Local cProduto := acols[n,aScan( aHeader, { |x| AllTrim(x[2])== "C6_PRODUTO"})]//Codigo do Produto
Local lItens   := If(!Empty(cProduto),.T.,.F.)

Default _cvend := M->C5_VEND1
Default _ccliente := M->C5_CLIENTE
Default _clojacli := M->C5_LOJACLI

Private lAchou := .F.
Private nPv    := aScan( aHeader, { |x| AllTrim(x[2])== "C6_COMIS1"}) //Comissao Vendedor
Private nPc    := aScan( aHeader, { |x| AllTrim(x[2])== "C6_COMIS2"}) //Comissao Coordenador
Private nPg	   := aScan( aHeader, { |x| AllTrim(x[2])== "C6_COMIS3"}) //Comissao Gerente
Private nPs    := aScan( aHeader, { |x| AllTrim(x[2])== "C6_COMIS4"}) //Comissao Supervisor
Private nPn    := aScan( aHeader, { |x| AllTrim(x[2])== "C6_COMIS5"}) //Comissao Gerente Nacional 

If lItens  

	acols[n,nPv] := 0
	acols[n,nPc] := 0
	acols[n,nPs] := 0
	
	//====================================================================================================
	// Filtro para selecao das Regras de Comissao
	//====================================================================================================
	cQry1	:=	" SELECT "
	cQry1 	+= 	"     ZAE_VEND   ,"
	cQry1 	+= 	"     ZAE_CLI    ,"
	cQry1 	+= 	"     ZAE_LOJA   ,"
	cQry1 	+= 	"     ZAE_GRPVEN ,"
	cQry1 	+= 	"     ZAE_COMIS1 ,"
	cQry1 	+= 	"     ZAE_COMIS2 ,"
	cQry1 	+= 	"     ZAE_COMIS3 ,"
	cQry1 	+= 	"     ZAE_COMIS4 ,"
	cQry1 	+= 	"     ZAE_COMIS5 ," 
	cQry1 	+= 	"     ZAE_COMVA1 ,"
	cQry1 	+= 	"     ZAE_COMVA2 ,"
	cQry1 	+= 	"     ZAE_COMVA3 ,"
	cQry1 	+= 	"     ZAE_COMVA4 ,"
	cQry1 	+= 	"     ZAE_COMVA5 ," 
	cQry1 	+= 	"     ZAE_CLI || ZAE_LOJA || ZAE_GRPVEN AS INDZAE "
	cQry1 	+= 	" FROM  "+ RETSQLNAME("ZAE")
	cQry1 	+= 	" WHERE "
	cQry1 	+= 	"     ZAE_FILIAL = '"+ xFilial("ZAE") +"' "
	cQry1 	+= 	" AND ZAE_VEND   = '"+ _cvend    +"' "
	cQry1 	+= 	" AND ZAE_PROD   = '"+ cProduto       +"' "
	cQry1 	+= 	" AND D_E_L_E_T_ = ' ' "
	cQry1 	+= 	" ORDER BY INDZAE DESC "
	
	If Select("TRBX") <> 0
		TRBX->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry1 ) , "TRBX" , .T., .F. )
	
	DBSelectArea("TRBX")
	If !TRBX->(Eof())
		
		DBSelectArea("SA1")
		DBSetOrder(1)
		DBSeek(xFilial("SA1")+_ccliente+_clojacli)
		
		TRBX->(DBGoTop())
		While TRBX->(!Eof())
			
			//====================================================================================================
			// 1 - Avalia se o cliente e loja sao iguais
			//====================================================================================================
			If AllTrim(_ccliente) == AllTrim(TRBX->ZAE_CLI) .And. AllTrim(_clojacli) == AllTrim(TRBX->ZAE_LOJA)
				AOMS013A()
				
			//====================================================================================================
			// 2 - Avalia se o cliente eh igual e a loja esta em branco
			//====================================================================================================
			ElseIf AllTrim(_ccliente) == AllTrim(TRBX->ZAE_CLI) .And. Empty(AllTrim(TRBX->ZAE_LOJA))
				AOMS013A()
				
			//====================================================================================================
			// 3 - Avalia se a Rede do cliente eh igual a rede informada na regra.
			//====================================================================================================
			ElseIf AllTrim(SA1->A1_GRPVEN) == AllTrim(TRBX->ZAE_GRPVEN)
				AOMS013A()
				
			//====================================================================================================
			// 4 - Avalia se o Contrato, Cliente e Grupo estao em branco.
			//====================================================================================================
			ElseIf Empty(AllTrim(TRBX->ZAE_CLI)) .And. Empty(AllTrim(TRBX->ZAE_GRPVEN))
				AOMS013A()
				
			EndIf
			
			//====================================================================================================
			// Se ja encontrei a comissao encerra o processamento
			//====================================================================================================
			If lAchou
				Exit
			EndIf
			
			TRBX->(DBSkip())
		EndDo
		
		TRBX->(DBCloseArea())

	EndIf
	
EndIf

FWRestArea(aArea)
Return( cProduto )

/*
===============================================================================================================================
Programa----------: AOMS013A
Autor-------------: Renato de Morcerf
Data da Criacao---: 02/09/2008
===============================================================================================================================
Descrição---------: Atualiza a comissão na tela do pedido
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS013A()
	Local _aComis      := {}
	Local _nPesRef     := U_ITGETMV( "IT_PESOVARE",4000)
	Local _nPesPed     := 0
	Local _nX          := 0
	Local _nPosProduto := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local _nPosQtd1    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_QTDVEN" })

	//Local _bSeekB1     := {|X| SB1->(DBSeek(xFilial("SB1")+X)) }

	//====================================================================================================
	// Calcula o peso bruto total dos itens do pedido
	//====================================================================================================
	If M->C5_I_PSORI == 0
		SB1->(DBSetOrder(1))
		_nPesPed := 0
		For _nX := 1 TO Len(aCols)
		    If !aTail(aCols[_nX]) 
			   SB1->(DBSeek(xFilial("SB1")+aCols[_nX][_nPosProduto]))//Eval(_bSeekB1, aCols[_nX][_nPosProduto])
			   _nPesPed += (SB1->B1_PESBRU * aCols[_nX][_nPosQtd1])
			EndIf
		Next
		M->C5_I_PSORI := _nPesPed
	Else
		_nPesPed := M->C5_I_PSORI
	EndIf

	If _nPesPed < _nPesRef .And. !(FunName() $ "AOMS061,MATA140,MATA521B,MATA460B,MATA103,AOMS032");
	   .And. !(ISINCALLSTACK("M520_VALID"))

		aAdd(_aComis, TRBX->ZAE_COMVA1)
		aAdd(_aComis, TRBX->ZAE_COMVA2)
		aAdd(_aComis, TRBX->ZAE_COMVA3)
		aAdd(_aComis, TRBX->ZAE_COMVA4)
		aAdd(_aComis, TRBX->ZAE_COMVA5) 
		M->C5_I_COMRE := "VV"

	Else
		aAdd(_aComis, TRBX->ZAE_COMIS1)
		aAdd(_aComis, TRBX->ZAE_COMIS2)
		aAdd(_aComis, TRBX->ZAE_COMIS3)
		aAdd(_aComis, TRBX->ZAE_COMIS4)
		aAdd(_aComis, TRBX->ZAE_COMIS5) 
		M->C5_I_COMRE := "VA"
	EndIf

	//====================================================================================================
	// Atualiza comissao vendedor
	//====================================================================================================
	acols[n,nPv] := _aComis[1]//Comissao do Produto

	//====================================================================================================
	// Atualiza comissao coordenador
	//====================================================================================================
	acols[n,nPc] := _aComis[2]

	//====================================================================================================
	// Atualiza comissao gerente
	//====================================================================================================
	acols[n,nPg] := _aComis[3]

	//====================================================================================================
	// Atualiza comissao supervisor
	//====================================================================================================
	acols[n,nPs] := _aComis[4]

    //====================================================================================================
	// Atualiza comissao gerente nacional
	//====================================================================================================
	acols[n,nPn] := _aComis[5]

	//====================================================================================================
	// Identifica que ja encontrou e atualizou a comissao
	//====================================================================================================
	lAchou := .T.

Return
