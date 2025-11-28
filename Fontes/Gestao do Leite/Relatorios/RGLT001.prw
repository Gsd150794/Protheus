/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre V. |26/05/2015| Chamados 9332/6460/8917/10299. Atualização das rotinas do Leite para remoção de campos.
 Lucas Borges |25/07/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "REPORT.CH"

/*
===============================================================================================================================
Programa----------: RGLT001
Autor-------------: Abrahao P. Santos
Data da Criacao---: 29/01/2009
Descrição---------: Relatório da Recepção de Leite diária por Produtor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT001

Local _nI := 0

Private _oReport	:= Nil
Private _oZLD		:= Nil
Private _oZLDA		:= Nil
Private _cPerg		:= "RGLT001"
Private _aValores	:= getaVal()
Private _nTot1		:= 0
Private _nTot2		:= 0
Private _nTot3		:= 0
Private _cDiaIni	:= " "
Private _cDiaFim	:= " "
Private _nColSize	:= 0
Private _cMasc		:= " "

Pergunte(_cPerg,.F.)

DEFINE REPORT _oReport NAME "RGLT001" TITLE "Mapa de Recebimento de Leite Próprio" PARAMETER _cPerg ACTION {|_oReport| PrintReport(_oReport)}

_oReport:HideParamPage()
_oReport:SetLandscape()
_oReport:SetTotalInLine(.F.)

DEFINE Section _oZLD OF _oReport TITLE "Recebimentos" TABLES "ZLD"
DEFINE CELL NAME "ZLD_FRETIS" 		OF _oZLD ALIAS "ZLD" TITLE "Fretista"
DEFINE CELL NAME "A2_NOME"   		OF _oZLD ALIAS "SA2" TITLE "Nome"

DEFINE Section _oZLDA OF _oZLD TITLE "Detalhes" TABLES "ZLD"
DEFINE CELL NAME "ZLD_RETIRO" 		OF _oZLDA ALIAS "ZLD" TITLE "Código"	SIZE 6.5
DEFINE CELL NAME "ZLD_RETILJ" 		OF _oZLDA ALIAS "ZLD" TITLE "Loja"		SIZE 4.5
DEFINE CELL NAME "ZLD_DCRRET" 		OF _oZLDA ALIAS "ZLD" TITLE "Produtor"	SIZE 20 PICTURE "@S20"

_nColSize	:= 5
_cMasc		:= "@E 999999"

DEFINE CELL NAME "01" OF _oZLDA ALIAS "ZLD" TITLE "01"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[01][02] }
DEFINE CELL NAME "02" OF _oZLDA ALIAS "ZLD" TITLE "02"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[02][02] }
DEFINE CELL NAME "03" OF _oZLDA ALIAS "ZLD" TITLE "03"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[03][02] }
DEFINE CELL NAME "04" OF _oZLDA ALIAS "ZLD" TITLE "04"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[04][02] }
DEFINE CELL NAME "05" OF _oZLDA ALIAS "ZLD" TITLE "05"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[05][02] }
DEFINE CELL NAME "06" OF _oZLDA ALIAS "ZLD" TITLE "06"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[06][02] }
DEFINE CELL NAME "07" OF _oZLDA ALIAS "ZLD" TITLE "07"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[07][02] }
DEFINE CELL NAME "08" OF _oZLDA ALIAS "ZLD" TITLE "08"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[08][02] }
DEFINE CELL NAME "09" OF _oZLDA ALIAS "ZLD" TITLE "09"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[09][02] }
DEFINE CELL NAME "10" OF _oZLDA ALIAS "ZLD" TITLE "10"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[10][02] }
DEFINE CELL NAME "11" OF _oZLDA ALIAS "ZLD" TITLE "11"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[11][02] }
DEFINE CELL NAME "12" OF _oZLDA ALIAS "ZLD" TITLE "12"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[12][02] }
DEFINE CELL NAME "13" OF _oZLDA ALIAS "ZLD" TITLE "13"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[13][02] }
DEFINE CELL NAME "14" OF _oZLDA ALIAS "ZLD" TITLE "14"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[14][02] }
DEFINE CELL NAME "15" OF _oZLDA ALIAS "ZLD" TITLE "15"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[15][02] }
DEFINE CELL NAME "T1" OF _oZLDA ALIAS "ZLD" TITLE "Total"		SIZE _nColSize PICTURE _cMasc BLOCK {|| _nTot1            }
DEFINE CELL NAME "16" OF _oZLDA ALIAS "ZLD" TITLE "16"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[16][02] }
DEFINE CELL NAME "17" OF _oZLDA ALIAS "ZLD" TITLE "17"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[17][02] }
DEFINE CELL NAME "18" OF _oZLDA ALIAS "ZLD" TITLE "18"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[18][02] }
DEFINE CELL NAME "19" OF _oZLDA ALIAS "ZLD" TITLE "19"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[19][02] }
DEFINE CELL NAME "20" OF _oZLDA ALIAS "ZLD" TITLE "20"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[20][02] }
DEFINE CELL NAME "21" OF _oZLDA ALIAS "ZLD" TITLE "21"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[21][02] }
DEFINE CELL NAME "22" OF _oZLDA ALIAS "ZLD" TITLE "22"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[22][02] }
DEFINE CELL NAME "23" OF _oZLDA ALIAS "ZLD" TITLE "23"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[23][02] }
DEFINE CELL NAME "24" OF _oZLDA ALIAS "ZLD" TITLE "24"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[24][02] }
DEFINE CELL NAME "25" OF _oZLDA ALIAS "ZLD" TITLE "25"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[25][02] }
DEFINE CELL NAME "26" OF _oZLDA ALIAS "ZLD" TITLE "26"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[26][02] }
DEFINE CELL NAME "27" OF _oZLDA ALIAS "ZLD" TITLE "27"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[27][02] }
DEFINE CELL NAME "28" OF _oZLDA ALIAS "ZLD" TITLE "28"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[28][02] }
DEFINE CELL NAME "29" OF _oZLDA ALIAS "ZLD" TITLE "29"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[29][02] }
DEFINE CELL NAME "30" OF _oZLDA ALIAS "ZLD" TITLE "30"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[30][02] }
DEFINE CELL NAME "31" OF _oZLDA ALIAS "ZLD" TITLE "31"			SIZE _nColSize PICTURE _cMasc BLOCK {|| _aValores[31][02] }
DEFINE CELL NAME "T2" OF _oZLDA ALIAS "ZLD" TITLE "Total"		SIZE _nColSize PICTURE _cMasc BLOCK {|| _nTot2            }
DEFINE CELL NAME "T3" OF _oZLDA ALIAS "ZLD" TITLE "Total Mês"	SIZE _nColSize PICTURE _cMasc BLOCK {|| _nTot3            }

//Filtra Data
_cDiaIni := MV_PAR09+MV_PAR10+IIf( MV_PAR11 > "01" , "16" , "01" )
_cDiaFim := MV_PAR09+MV_PAR10+IIf( MV_PAR12 > "01" , "31" , "15" )

_oZLDA:SetLineCondition( {|| ProcLinha(QRYZLD->ZLD_RETIRO,QRYZLD->ZLD_RETILJ,QRYZLD->ZLD_FRETIS,QRYZLD->ZLD_LJFRET,_cDiaIni,_cDiaFim) } )

For _nI := 4 to 37
	_oZLDA:Cell(_nI):SetHeaderAlign("RIGHT")
Next _nI

_oZLD:SetPageBreak(.T.)					//Seta para cada quebra de secao saltar pagina
_oZLDA:SetTotalInLine(.F.)				//Seta para imprimir totais em coluna e nao no fim do report
_oZLDA:SetTotalText("Total da Linha:")	//Seta texto padrao que sera impresso

For _nI := 4 to 37
	DEFINE FUNCTION FROM _oZLDA:Cell(_nI) FUNCTION SUM
Next _nI

_oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: PrintReport
Autor-------------: Jeovane
Data da Criacao---: 24/09/2008
Descrição---------: Printa o relatorio
Parametros--------: _oReport
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PrintReport(_oReport)

BEGIN REPORT QUERY _oReport:Section(1)
	
BeginSql alias "QRYZLD"
    SELECT DISTINCT ZLD.ZLD_RETIRO, ZLD.ZLD_RETILJ,
                    (SELECT C.A2_NOME
                       FROM %Table:SA2% C
                      WHERE C.D_E_L_E_T_ = ' '
                        AND C.A2_COD = ZLD.ZLD_RETIRO
                        AND C.A2_LOJA = ZLD.ZLD_RETILJ) ZLD_DCRRET,
                    ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, SA2.A2_NOME
      FROM %Table:ZLD% ZLD, %Table:SA2% SA2
     WHERE ZLD.D_E_L_E_T_ = ' '
       AND SA2.D_E_L_E_T_ = ' '
       AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
       AND ZLD.ZLD_FRETIS = SA2.A2_COD
       AND ZLD.ZLD_LJFRET = SA2.A2_LOJA
       AND ZLD.ZLD_FRETIS BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
       AND ZLD.ZLD_LJFRET BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
       AND ZLD.ZLD_RETIRO BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
       AND ZLD.ZLD_RETILJ BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
       AND ZLD.ZLD_DTCOLE BETWEEN %exp:_cDiaIni% AND %exp:_cDiaFim%
     ORDER BY ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLD.ZLD_RETIRO, ZLD.ZLD_RETILJ
EndSql
END REPORT QUERY _oReport:Section(1)
      
_oReport:Section(1):Section(1):SetParentQuery()
_oReport:Section(1):Section(1):SetParentFilter({|cParam| QRYZLD->ZLD_FRETIS+QRYZLD->ZLD_LJFRET == cParam },{|| QRYZLD->ZLD_FRETIS+QRYZLD->ZLD_LJFRET })   
_oReport:Section(1):Print(.T.)

Return

/*
===============================================================================================================================
Programa----------: procLinha
Autor-------------: Jeovane
Data da Criacao---: 24/09/2008
Descrição---------: Funcao chamada no linecondition da secao do relatorio, atualiza variavel privada _aValores com respectivos
					valores da linha
Parametros--------: cProdutor,cLoja,cFretista,cLjFret,_cDiaIni,_cDiaFim
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function procLinha(cProdutor,cLoja,cFretista,cLjFret,_cDiaIni,_cDiaFim)

Local _lRet		:= .T.
Local _cAlias	:= GetNextAlias()
Local _aArea	:= FWGetArea()
Local _nI		:= 0

_nTot1 := 0
_nTot2 := 0
_nTot3 := 0

_aValores := getaVal()

BeginSql alias _cAlias
	SELECT SubStr(ZLD_DTCOLE, 7, 2) DIA, COALESCE(SUM(ZLD_QTDBOM), 0) BOM
	  FROM %Table:ZLD%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLD_FILIAL = %xFilial:ZLD%
	   AND ZLD_DTCOLE BETWEEN %exp:_cDiaIni% AND %exp:_cDiaFim%
	   AND ZLD_RETIRO = %exp:cProdutor%
	   AND ZLD_RETILJ = %exp:cLoja%
	   AND ZLD_FRETIS = %exp:cFretista%
	   AND ZLD_LJFRET = %exp:cLjFret%
	 GROUP BY SubStr(ZLD_DTCOLE, 7, 2)
EndSql

//Atualiza valores na matriz de acordo com query
While (_cAlias)->(!Eof())
	nIndex := aScan( _aValores , {|x| x[1] == (_cAlias)->DIA } )
	_aValores[nIndex][02] := (_cAlias)->BOM
	(_cAlias)->( DBSkip() )
EndDo
(_cAlias)->(DBCloseArea())

//Atualiza Variaveis de totalizadores de quinzena
For _nI := 1 to 15
	_nTot1 += _aValores[_nI][02]
Next _nI

For _nI := 16 to 31
	_nTot2 += _aValores[_nI][02]
Next _nI

_nTot3 += _nTot1 + _nTot2

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: getaVal
Autor-------------: Jeovane
Data da Criacao---: 24/09/2008
Descrição---------: Funcao usada para preencher vetor _aValores com valores padrao
Parametros--------: Nenhum
Retorno-----------: _aRet
===============================================================================================================================
*/
Static Function getaVal()

Local _aRet	:= {}
Local _nX	:= 0

//Preenche Matriz a Valores default
For _nX := 1 to 31
	aAdd(_aRet,{StrZero(_nX,2),0})
Next _nX

Return( _aRet )
