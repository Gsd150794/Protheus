/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |04/09/2024| Chamado 48421. Considerar data de contabilização ao invés da data de emissão
Antonio Neves |17/10/2024| Chamado 48878. Inclusão da Coluna Parcela
Igor Melgaço  |25/10/2024| Chamado 48878. Inclusão da Coluna Parcela
=========================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RFIS011
Autor-----------: Igor Melgaço
Data da Criacao-: 07/11/2023   
Descrição-------: Relação para extração e integração dos blocos R4010 e R4020. Chamado 41268  
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function RFIS011

Local _aParAux  := {} , nI
Local _aParRet  := {}

MV_PAR01 := Space(200)
MV_PAR02 := CTOD("")
MV_PAR03 := CTOD("")

aAdd( _aParAux , { 1 , "Filial"           , MV_PAR01, "@!"  , ""  ,"LSTFIL", "" , 060 , .F. } ) 
aAdd( _aParAux , { 1 , "Emissão de"	 		, MV_PAR02, "@D"	, ""  , ""	   , "" , 50  , .T. } )
aAdd( _aParAux , { 1 , "Emissão ate" 		, MV_PAR03, "@D"	, ""  , ""	   , "" , 50  , .T. } )

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 

While ParamBox( _aParAux , "SELECIONE OS FILTROS" , _aParRet , {|| .T. } , , , , , , , .T. , .T. )
	FWMsgRun(,{|oproc|  RFIS011PROC(oProc) },'Aguarde processamento...','Lendo dados...')
EndDo

Return

/*
===============================================================================================================================
Programa--------: RFIS011PROC 
Autor-----------: Igor Melgaço
Data da Criacao-: 07/11/2023   
Descrição-------: Rotina de Processamento da Listagem. 
Parametros------: oProc = Objeto da regua de processamento
Retorno---------: NENHUM
===============================================================================================================================
*/
Static Function RFIS011PROC(oproc)
Local _aDados := {}
Local _aCab := {}
Local _aCabXML := {}

_aDados := RFIS011QRY(oproc)

If Len(_aDados) = 0 
    U_ITMsg("Não há dados no periodo.","Envio do E-MAIL",,3)
Else
	_cTitulo := "Previsão REINF 4010-4020 "

	aAdd(_aCab,"Bloco")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Filial")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Natureza")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"CGC/CPF")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Cod Forn.")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Loja")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Razão Social")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Título")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Parcela")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"FAT_BX")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Dt_Contab")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Baixa")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,3           ,1         ,.F.})
	aAdd(_aCab,"Vr Título")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,3           ,3         ,.F.})
	aAdd(_aCab,"IRRF")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,3           ,3         ,.F.})
	aAdd(_aCab,"PIS")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,3           ,3         ,.F.})
	aAdd(_aCab,"COFINS")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,3           ,3         ,.F.})
	aAdd(_aCab,"CSLL")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,3           ,3         ,.F.})
	aAdd(_aCab,"Vr Nota Fiscal")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,3           ,3         ,.F.})
	aAdd(_aCab,"Cod. Ret. IR")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})
	aAdd(_aCab,"Cod. Ret. PCC")
	aAdd(_aCabXML,{_aCab[Len(_aCab)]   ,1           ,1         ,.F.})

						 //             , _aCols   ,_lMaxSiz  ,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab     , bDblClk , _aColXML , bCondMarca )
	U_ITListBox(_cTitulo,_aCab     ,_aDados[1]   , .T.      , 1    ,        ,          ,        ,         ,     ,        ,          , _aCabXML  ,         ,_aDados[2]          ,            )

EndIf

Return 

/*
===============================================================================================================================
Programa--------: RFIS011QRY 
Autor-----------: Igor Melgaço
Data da Criacao-: 07/11/2023   
Descrição-------: Processamento da Query 
Parametros------: oProc = Objeto da regua de processamento
Retorno---------: _aDados = Dados de retorno do processamento da query
===============================================================================================================================
*/
Static Function RFIS011QRY(oproc)

Local _cAliasQRY := ''
Local _cFiltro	  := ''
Local _aDados    := {}
Local _aDadosXml := {}
Local _nAtual    := 0
Local _nCol      := 0

_cAliasQRY := GetNextAlias()

_cFiltro += "% "

If !Empty(MV_PAR03)
   _cFiltro += " BETWEEN '"+ DToS(MV_PAR02) +"' AND '"+ DToS(MV_PAR03) +"' "
EndIf


If !Empty(AllTrim(MV_PAR01))
	_cFiltro += " AND E2_FILIAL IN " +FormatIn(AllTrim(MV_PAR01),";")
EndIf


_cFiltro += " %"

BeginSql Alias _cAliasQRY


SELECT BLOCO,
       FILIAL,
	   NATUREZA,
	   CGC,
       COD_FORNECE,
       LOJA,
       RAZAO_SOCIAL,
       TITULO,
	   PREFIXO,
	   PARCELA,
       FAT_BX,
       DT_CONTAB,
       BAIXA,
	   Case 
	   WHEN SUM(IRRF)>0 AND PESSOA = 'J' AND PREFIXO<>'MAN' AND SubStr(COD_FORNECE,1,1) <> 'V' THEN '1708' 
	   WHEN SUM(IRRF)>0 AND PESSOA = 'F' AND PREFIXO = 'MAN' AND SubStr(COD_FORNECE,1,1) <> 'V' THEN '3208'
	   WHEN SUM(IRRF)>0 AND SubStr(COD_FORNECE,1,1)='V' THEN '8045'
	   Else ' ' 
	   END AS CODRET_IR,
	   Case
	   WHEN SUM(PIS)=0 AND SUM(COFINS)=0 AND SUM(CSLL)>0 THEN '5987'
	   WHEN SUM(PIS)>0 AND SUM(COFINS)>0 AND SUM(CSLL)>0 THEN '5952'
	   Else ' ' 
	   END AS CODRET_PCC,
       SUM(VALOR) VAL_TITULO,
       SUM(IRRF) IRRF,
       SUM(PIS) PIS,
       SUM(COFINS) COFINS,
       SUM(CSLL) CSLL,
       SUM(TOT_NF) VAL_NF
FROM
	(
		SELECT 'BLC-4010' BLOCO,
			E2_FILIAL FILIAL,
			E2_NATUREZ NATUREZA,
			A2_CGC CGC,
			E2_FORNECE COD_FORNECE,
			E2_LOJA LOJA,
			E2_NUM TITULO,
			E2_PREFIXO PREFIXO,
			E2_PARCELA PARCELA,
			A2_NOME RAZAO_SOCIAL,
			A2_TIPO PESSOA,
            'FAT' FAT_BX,
			E2_EMIS1 DT_CONTAB,
			E2_BAIXA BAIXA,
			(E2_VALOR+E2_IRRF+E2_PIS+E2_COFINS+E2_CSLL) VALOR,
			E2_IRRF IRRF,
			0 PIS,
			0 COFINS,
			0 CSLL,
			NVL(
					(SELECT SUM(D1_TOTAL)
						FROM
						%Table:SD1% SD1 
						WHERE D1_FILIAL = E2_FILIAL
						AND D1_DOC = E2_NUM
						AND D1_SERIE = E2_PREFIXO
						AND D1_FORNECE = E2_FORNECE
						AND D1_LOJA = E2_LOJA
						AND SD1.D_E_L_E_T_ =' '),0
				) TOT_NF

		FROM	%Table:SE2% SE2 
			INNER JOIN 	%Table:SA2% SA2 ON A2_COD = E2_FORNECE AND A2_LOJA = E2_LOJA AND SA2.D_E_L_E_T_ =' ' AND A2_TIPO='F'
		WHERE 
			SE2.D_E_L_E_T_ =' '
            AND E2_IRRF>0 AND E2_PREFIXO <> 'AUT'
			AND 
            E2_EMIS1  			
			%exp:_cFiltro%

   	
		UNION ALL
		
		SELECT 'BLC-4020' BLOCO,
			E2_FILIAL FILIAL,
			E2_NATUREZ NATUREZA,
			A2_CGC CGC,
			E2_FORNECE COD_FORNECE,
			E2_LOJA LOJA,
			E2_NUM TITULO,
			E2_PREFIXO PREFIXO,
			E2_PARCELA PARCELA,
			A2_NOME RAZAO_SOCIAL,
			A2_TIPO PESSOA,
            'FAT' FAT_BX,
			E2_EMIS1 DT_CONTAB,
			E2_BAIXA BAIXA,
			(E2_VALOR+E2_IRRF+E2_PIS+E2_COFINS+E2_CSLL) VALOR,
			E2_IRRF IRRF,
			0 PIS,
			0 COFINS,
			0 CSLL,
			NVL(
					(SELECT SUM(D1_TOTAL)
						FROM %Table:SD1% SD1 
						WHERE D1_FILIAL = E2_FILIAL
						AND D1_DOC = E2_NUM
						AND D1_SERIE = E2_PREFIXO
						AND D1_FORNECE = E2_FORNECE
						AND D1_LOJA = E2_LOJA
						AND SD1.D_E_L_E_T_ =' '),0
				) TOT_NF
				FROM %Table:SE2% SE2
			INNER JOIN %Table:SA2% SA2 ON A2_COD = E2_FORNECE AND A2_LOJA = E2_LOJA AND SA2.D_E_L_E_T_ =' '	AND A2_TIPO='J'
		WHERE 
			SE2.D_E_L_E_T_ =' '
            AND E2_IRRF>0 AND E2_PREFIXO <>'AUT'
			AND 
			E2_EMIS1  
			%exp:_cFiltro%

		UNION ALL
	
		SELECT 'BLC-4020' BLOCO,
			E2_FILIAL FILIAL,
			E2_NATUREZ NATUREZA,
			A2_CGC CGC,
			E2_FORNECE COD_FORNECE,
			E2_LOJA LOJA,
			E2_NUM TITULO,
			E2_PREFIXO PREFIXO,
			E2_PARCELA PARCELA,
			A2_NOME RAZAO_SOCIAL,
			A2_TIPO PESSOA,
            'BAIXA' FAT_BX,
			E2_EMIS1 DT_CONTAB,
			E2_BAIXA BAIXA,
			(E2_VALOR+E2_IRRF+E2_PIS+E2_COFINS+E2_CSLL) VALOR,
			0 IRRF,
			E2_PIS PIS,
			E2_COFINS COFINS,
			E2_CSLL CSLL,
			NVL(
					(SELECT SUM(D1_TOTAL)
					FROM %Table:SD1% SD1 
					WHERE D1_FILIAL = E2_FILIAL
						AND D1_DOC = E2_NUM
						AND D1_SERIE = E2_PREFIXO
						AND D1_FORNECE = E2_FORNECE
						AND D1_LOJA = E2_LOJA
						AND SD1.D_E_L_E_T_ =' '),0) TOT_NF

					FROM %Table:SE2% SE2 
			INNER JOIN %Table:SA2% SA2  ON A2_COD = E2_FORNECE AND A2_LOJA = E2_LOJA	AND SA2.D_E_L_E_T_ =' ' AND A2_TIPO='J'
		WHERE 
			 SE2.D_E_L_E_T_ =' '
			AND (E2_COFINS>0 OR E2_PIS >0 OR E2_CSLL>0) AND E2_PREFIXO <>'AUT'
			AND E2_BAIXA 
			%exp:_cFiltro%

	)
GROUP BY BLOCO,
         FILIAL,
		 NATUREZA,
		 CGC,
         COD_FORNECE,
         LOJA,
         TITULO,
 		 PREFIXO,
		 PARCELA,
         RAZAO_SOCIAL,
		 PESSOA,
         FAT_BX,
         DT_CONTAB,
         BAIXA,
         VALOR
ORDER BY 1,2,4,8





EndSql

DBSelectArea(_cAliasQRY)
COUNT TO nTotal

(_cAliasQRY)->(DBGoTop())
If !(_cAliasQRY)->(Eof())


	ProcRegua(nTotal)
	While !(_cAliasQRY)->(Eof())
		_nAtual++
		aAdd(_aDadosXml,{	(_cAliasQRY)->BLOCO,;
						(_cAliasQRY)->FILIAL,;
						(_cAliasQRY)->NATUREZA,;
						(_cAliasQry)->CGC,;
						(_cAliasQRY)->COD_FORNECE,;
						(_cAliasQRY)->LOJA,;
						(_cAliasQRY)->RAZAO_SOCIAL,;
						(_cAliasQRY)->TITULO,;
						(_cAliasQry)->PARCELA,;
						(_CAliasQRY)->FAT_BX,;
						DToC(SToD((_cAliasQRY)->DT_CONTAB)),;
						DToC(SToD((_cAliasQRY)->BAIXA)),;
						(_cAliasQRY)->VAL_TITULO,; //11
						(_cAliasQRY)->IRRF,;
						(_cAliasQRY)->PIS,;						
						(_cAliasQRY)->COFINS,;
						(_cAliasQRY)->CSLL,;
						(_cAliasQRY)->VAL_NF,; //16
						IIf(SToD((_cAliasQRY)->DT_CONTAB)<MV_PAR02 .Or. SToD((_cAliasQRY)->DT_CONTAB)>MV_PAR03,' ',(_cAliasQRY)->CODRET_IR),;
						IIf(SToD((_cAliasQRY)->BAIXA)>MV_PAR03,' ',(_cAliasQRY)->CODRET_PCC) })

		aAdd(_aDados,_aDadosXml[Len(_aDadosXml)])

		For _nCol := 13 To 18
			_aDados[Len(_aDados),_nCol] := Transform(_aDados[Len(_aDados),_nCol],"@E 99,999,999,999.99")
		Next

		(_cAliasQRY)->(DBSkip())
		
		oproc:cCaption := ("Processando " + cValToChar(_nAtual) + " de " + cValToChar(nTotal) + "...")
		ProcessMessages()
	EndDo
	(_cAliasQRY)->( DBCloseArea() )
EndIf

Return {_aDados,_aDadosXml}
