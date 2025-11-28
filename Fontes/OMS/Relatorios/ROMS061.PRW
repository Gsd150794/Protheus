/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |18/08/2022| Chamado 44573. Acrescentar campo produtos: ativo / inativo na listagem.
Igor Melgaço  |13/08/2021| Chamado 47739. Inclusão do campo DA1_ATIVO. 
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "report.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: ROMS061
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/04/2021
Descrição---------: Relatorio de Tabela de Preços. Chamado 33052.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS061()

Local _cPerg := "ROMS061"

While .T.

	//==================================================================
	// Exibe tela de parâmetros inicias.
	//==================================================================
	If ! Pergunte(_cPerg , .T.)
		Break
	EndIf

    _lRet:=.T.
	Processa( {|| _lRet := U_ROMS061A() }, "Aguarde...", "Emitindo o Relatório...",.F.)
	If !_lRet
	   Exit
	EndIf

EndDo

Return

/*
===============================================================================================================================
Programa----------: ROMS061A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2020
Descrição---------: Gera os dados e emite o relatório.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS061A()
Local _cQry , _lRet:=.F.
Local _nTotRegs, _aTitulos
Local _aDados, _nI

Begin Sequence
		//==================================================================
		// Filtra os dados da tabela de preços para emissão do relatório.
		//==================================================================
		_cQry := "SELECT "
		_cQry += " DA1_CODTAB, "  // Cod.Tab. Preço
		_cQry += " DA0_DESCRI, "  // Tabela Preço",
		_cQry += " DA0_ATIVO, "   // DECODE ( DA0_ATIVO, 1, 'SIM', 2, 'NAO') "Ativo",
		_cQry += " DA0_DATDE, "   // Início Vigência",
		_cQry += " DA0_DATATE, "  // Fim Vigência",
		_cQry += " DA1_CODPRO, "  // Cod.Produto",
		_cQry += " B1_DESC, "     // Produto",
		_cQry += " B1_GRUPO, "
		_cQry += " DA1_PRCVEN, "  // PR Carga Fech",
		_cQry += " DA1_I_PMFE, "  // PR Min Carga Fech",
		_cQry += " DA1_I_PRFE, "  // PR Carga Frac",
		_cQry += " DA1_I_PMFR, "  // PR Min Carga Frac",
		_cQry += " DA1_PRCMAX, "  // PR Max ",
		_cQry += " B1_I_BIMIX, "   //  MIX"
		_cQry += " DA0_I_PES1, "   // Peso Faixa 1"
		_cQry += " DA1_I_PRF1, "   // Pr Faixa 1,
		_cQry += " DA1_I_PMF1, "   // Pr min Fx 1,
		_cQry += " DA0_I_PES2, "   // Peso Faixa 2,
		_cQry += " DA1_I_PRF2, "   // Pr Faixa 2,
		_cQry += " DA1_I_PMF2, "   // Pr min Fx 2,
		_cQry += " DA0_I_PES3, "   // Peso Faixa 3,
		_cQry += " DA1_I_PRF3, "   // Pr Faixa 3,
		_cQry += " DA1_I_PMF3, "    // Pr min Fx 3
      _cQry += " DA1_ATIVO "
		_cQry += " FROM "
		_cQry += " " + RetSqlName("DA1") + " DA1, " // da1010 da1,
		_cQry += " " + RetSqlName("DA0") + " DA0, " // A0010 DA0,
		_cQry += " " + RetSqlName("SB1") + " SB1, " // sb1010 sb1
		_cQry += " WHERE "
		_cQry += " DA1.D_E_L_E_T_ = ' ' "
		_cQry += " AND DA1_FILIAL = '" + xFilial("DA1") + "' "
		_cQry += " AND DA1_CODTAB >= '100' "
		_cQry += " AND DA0_FILIAL = DA1_FILIAL "
		_cQry += " AND DA0_CODTAB = DA1_CODTAB "
		_cQry += " AND DA0.D_E_L_E_T_ = ' ' "
		_cQry += " AND B1_FILIAL = ' ' "
		_cQry += " AND B1_COD = DA1_CODPRO "
		_cQry += " AND SB1.D_E_L_E_T_ = ' ' "

		If ! Empty(MV_PAR01) // "Cód.Inicial Tabela Preços"
			_cQry += " AND DA1_CODTAB >= '" + MV_PAR01 + "' "
		EndIf

		If ! Empty(MV_PAR02)  // "Cód.Final Tabela Preços"
			_cQry += " AND DA1_CODTAB <= '" + MV_PAR02 + "' "
		EndIf

		If ! Empty(MV_PAR03)  // "De Vigência"
			_cQry += " AND DA0_DATDE >= '" + DToS(MV_PAR03) + "' "   // Início Vigência",

		EndIf

		If ! Empty(MV_PAR04)  // "Até Vigência"
			_cQry += " AND DA0_DATATE <= '" + DToS(MV_PAR04) + "' "
		EndIf

		If ! Empty(MV_PAR05)  // "Ativa" //  DA0_ATIVO, 1, 'SIM', 2, 'NAO'
			If MV_PAR05 == 1
				_cQry += " AND DA0_ATIVO = '1' "
			ElseIf MV_PAR05 == 2
				_cQry += " AND DA0_ATIVO = '2' "
			EndIf
		EndIf

		If ! Empty(MV_PAR06) // "Mix"   // G1=Grupo 1;G2=Grupo 2;G3=Grupo 3;G9=Outros;G0=Indefinido
			_cQry += " AND B1_I_BIMIX = '" + MV_PAR06 + "' "
		EndIf

		_cQry += " ORDER BY "
		_cQry += " DA1_CODTAB, "
		//_cQry += " DA1_I_MIX, "
		_cQry += " B1_DESC "

		If Select("QRYDA1") > 0
			QRYDAK->(DBCloseArea())
		EndIf

		_cQry := ChangeQuery(_cQry)
		DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYDA1", .F., .T.)
		TCSetField( "QRYDA1", "DA0_DATDE" , "D", 8 )
		TCSetField( "QRYDA1", "DA0_DATATE", "D", 8 )
		TCSetField( "QRYDA1", "DA1_PRCVEN", "N", 16, 2 ) // PR Carga Fech
		TCSetField( "QRYDA1", "DA1_I_PMFE", "N", 16, 2 ) // PR Min Carga Fech
		TCSetField( "QRYDA1", "DA1_I_PRFE", "N", 16, 2 ) // PR Carga Frac
		TCSetField( "QRYDA1", "DA1_I_PMFR", "N", 16, 2 ) // PR Min Carga Frac
		TCSetField( "QRYDA1", "DA1_PRCMAX", "N", 16, 2 ) // PR Max
		TCSetField( "QRYDA1", "DA0_I_PES1", "N", 16, 2 ) // Peso Faixa 1,
		TCSetField( "QRYDA1", "DA1_I_PRF1", "N", 16, 2 ) // Pr Faixa 1,
		TCSetField( "QRYDA1", "DA1_I_PMF1", "N", 16, 2 ) // Pr min Fx 1,
		TCSetField( "QRYDA1", "DA0_I_PES2", "N", 16, 2 ) // Peso Faixa 2,
		TCSetField( "QRYDA1", "DA1_I_PRF2", "N", 16, 2 ) // Pr Faixa 2,
		TCSetField( "QRYDA1", "DA1_I_PMF2", "N", 16, 2 ) // Pr min Fx 2,
		TCSetField( "QRYDA1", "DA0_I_PES3", "N", 16, 2 ) // Peso Faixa 3,
		TCSetField( "QRYDA1", "DA1_I_PRF3", "N", 16, 2 ) // Pr Faixa 3,
		TCSetField( "QRYDA1", "DA1_I_PMF3", "N", 16, 2 ) // Pr min Fx 3
      TCSetField( "QRYDA1", "DA1_ATIVO" , "C", 1 )

		Count To _nTotRegs

		If _nTotRegs == 0
           U_ITMsg("Não há dados para esses filtros.","Atenção","Tente novamente com outros filtros.",1)
		   _lRet:=.T.
		   Break
		EndIf

		ProcRegua(_nTotRegs)

		QRYDA1->(DBGoTop())

		_aDados := {}
		_nI := 0

		While ! QRYDA1->(Eof())
			_nI += 1
			IncProc("Lendo dados Tabela de Preços: " + AllTrim(QRYDA1->DA1_CODTAB) + " - Item: " + StrZero(_nI,6) + "/" + StrZero(_nTotRegs,6))

			aAdd(_aDados,{QRYDA1->DA1_CODTAB,;  // Cod.Tab. Preço
			QRYDA1->DA0_DESCRI,;  // Tabela Preço",
			QRYDA1->DA1_CODPRO,;  // Cod.Produto",
			QRYDA1->B1_DESC,;     // Produto",
			QRYDA1->B1_GRUPO,;    // Grupo de Produtos
			QRYDA1->DA0_I_PES1,;  // Peso Faixa 1,
			QRYDA1->DA0_I_PES2,;  // Peso Faixa 2,
			QRYDA1->DA0_I_PES3,;  // Peso Faixa 3,			
			QRYDA1->DA1_I_PRF1,;  // Pr Faixa 1,
			QRYDA1->DA1_I_PMF1,;  // Pr min Fx 1,
			QRYDA1->DA1_I_PRF2,;  // Pr Faixa 2,
			QRYDA1->DA1_I_PMF2,;  // Pr min Fx 2,
			QRYDA1->DA1_I_PRF3,;  // Pr Faixa 3,
			QRYDA1->DA1_I_PMF3,;  // Pr min Fx 3
			QRYDA1->DA1_PRCMAX,;  // PR Max,
			IIf(QRYDA1->DA1_ATIVO == "2","Nao","Sim") })  // Ativo?

			QRYDA1->(DBSkip())
		EndDo
 
		_aTitulos := {"Cod.Tab. Preço",;
			          "Tabela Preço",;
			          "Cod.Produto",;
			          "Produto",;
			          "Grupo Produto",;
			          "Peso Faixa 1",; 
			          "Peso Faixa 2",;
			          "Peso Faixa 3",;			
			          "Pr Faixa 1",;
			          "Pr min Fx 1",;
			          "Pr Faixa 2",;
			          "Pr min Fx 2",;
			          "Pr Faixa 3",;
			          "Pr min Fx 3",;
			          "PR Max",;
			          "Bloqueio Produto"}
   
   If Len(_aDados) > 0
	
	  _lRet:=U_ITListBox( 'Relatorio de Tabelas de Preços' ,  _aTitulos , _aDados , .T. ,1)
   
   Else

      U_ITMsg("Não há dados para esses filtros.","Atenção","Tente novamente com outros filtros.",1)
	  _lRet:=.T.
   
   EndIf

End Sequence

If Select("QRYDA1") > 0
	QRYDA1->(DBCloseArea())
EndIf

Return _lRet
