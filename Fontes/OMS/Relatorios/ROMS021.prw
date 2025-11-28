/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |27/11/2023| Chamado 45390. Tratativa para a perda do credeciamento do Transportador junto ao SEFAZ.
Antonio Neves |31/05/2024| Chamado 47416. Alterar a alíquota da UF = GO. Criado parâmetro.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
 
#Include "report.ch"
#Include "TOTVS.ch"
  
/*
===============================================================================================================================
Programa----------: ROMS021
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 09/09/2010
Descrição---------: Relatorio utilizado para exibir os dados do ICMS sobre frete cobrado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS021()

Private _cEstFil	:= SM0->M0_ESTENT
Private _cEstDif	:= GetMV( 'IT_UFALICM' ,, 'MG/SP/RJ/PR/SC/RS' )
Private QRY

Private cPerg		:= "ROMS021"
Private cNomeFil	:= ""
Private oReport		:= NIL
Private oSecFil		:= NIL
Private oSecDados	:= NIL
Private oBreakFil	:= NIL

Pergunte( cPerg , .F. )

DEFINE REPORT oReport NAME cPerg TITLE "ICMS DO FRETE" PARAMETER cPerg ACTION {|oReport| PrintReport(oReport)} Description "Este relatório emitirá a relação de ICMS do Frete referente ao período informado, para os estados diferentes do da Filial corrente."

//Seta Padrao de impressao como Paisagem
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)              
                             
oReport:nFontBody	:= 08
oReport:cFontBody	:= "Courier New"  
oReport:nLineHeight	:= 50 // Define a altura da linha.

oReport:SetMsgPrint('AGUARDE OS DADOS DO RELATORIO ESTAO SENDO PROCESSADOS')//mensagem exibida no momento da impressao

//===============================
// Define dados da secao Filial |
//===============================

DEFINE Section oSecFil OF oReport TITLE "Filial" TABLES "SF2","SA2","SA1"

oSecFil:SetLineStyle(.T.)  
oSecFil:SetLinesBefore(3) 
 
DEFINE Section oSecDados OF oSecFil TITLE "Dados" TABLES "SF2","SA2","SA1","DA4"

DEFINE CELL NAME "F2_EMISSAO"	OF oSecDados ALIAS "SF2" TITLE "Data"                 SIZE 15   
DEFINE CELL NAME "NOTAFIS"      OF oSecDados ALIAS ""    TITLE "Nota Fiscal"          SIZE 18 BLOCK{|| QRY->F2_DOC + '/' + QRY->F2_SERIE}
DEFINE CELL NAME "F2_I_FRET"    OF oSecDados ALIAS ""    TITLE "Base do Calculo"      SIZE 20 PICTURE "@E 9,999,999,999.99"

//DEFINE CELL NAME "vlrICMS"      OF oSecDados ALIAS ""    TITLE "Valor ICMS"           SIZE 20 PICTURE "@E 9,999,999,999.99" BLOCK{|| ( QRY->F2_I_FRET * IIf( _cEstFil $ _cEstDif .And. !( QRY->F2_EST $ _cEstDif ) , 0.07 , 0.12 ) ) }
DEFINE CELL NAME "vlrICMS"  	OF oSecDados ALIAS ""    TITLE "Valor ICMS"           SIZE 20 PICTURE "@E 9,999,999,999.99" BLOCK {|| ROMS021AL() }
DEFINE CELL NAME "vlrPres"      OF oSecDados ALIAS ""    TITLE "Credito Presumido"    SIZE 25 PICTURE "@E 9,999,999,999.99" BLOCK{|| ( ( QRY->F2_I_FRET * IIf( _cEstFil $ _cEstDif .And. !( QRY->F2_EST $ _cEstDif ) , 0.07 , 0.12 ) ) - ( ( QRY->F2_I_FRET * IIf( _cEstFil $ _cEstDif .And. !( QRY->F2_EST $ _cEstDif ) , 0.07 , 0.12 ) ) * 0.2 ) ) }
DEFINE CELL NAME "Transport"    OF oSecDados ALIAS ""    TITLE "Transportadora"       SIZE 45 BLOCK{|| IIf(QRY->A2_I_CLASS == 'A',"TERCEIROS",AllTrim(QRY->F2_I_CTRA) + '/' + AllTrim(QRY->F2_I_LTRA) + '-' + AllTrim(QRY->A2_NOME) + ' ' + AllTrim(QRY->A2_EST)) }
DEFINE CELL NAME "Motorist"     OF oSecDados ALIAS ""    TITLE "Motorista"            SIZE 40 BLOCK{|| IIf(QRY->A2_I_CLASS $ 'T/G/C',"",AllTrim(QRY->DA4_COD) + '-' + AllTrim(QRY->DA4_NOME) ) }
DEFINE CELL NAME "MUN_EST"      OF oSecDados ALIAS ""    TITLE "Cidade - UF do Cliente"          SIZE 35 
DEFINE CELL NAME "UFTRANSP"     OF oSecDados ALIAS ""    TITLE "Cidade - UF do Transportador"    SIZE 35 

//Desabilita Secao                   
oSecDados:SetLinesBefore(2)  
oSecDados:SetCellBorder(5,2,,.T.)
oSecDados:SetCellBorder(5,2,,.F.) 
oSecDados:SetAutoSize(.T.)          
oSecDados:SetHeaderPage(.T.)     
 
If _cEstFil <> 'MG'      
	oSecDados:Cell("vlrPres"):Disable()
EndIf

//Alinhamento de cabecalho                             
oSecDados:Cell("F2_I_FRET"):SetHeaderAlign("RIGHT")  
oSecDados:Cell("vlrICMS"):SetHeaderAlign("RIGHT")       

oSecDados:SetTotalInLine(.F.)       

oReport:PrintDialog()

Return               

Static Function PrintReport(oReport) 

Local _cFiltro := "%"
 
oReport:SetTitle("ICMS DO FRETE REFERENTE AO PERÍODO DE " + DToC(MV_PAR01) + " A "  + DToC(MV_PAR02))

//Permitir listar Notas cujo a UF do Cliente esteja igual UF da Filial e o Transportador com UF diferente.
  
If _cEstFil == 'GO'
	_cFiltro += " AND SA2.A2_I_I1298 NOT IN ('S', 'L') AND SA2.A2_I_CLASS IN ('T', 'A', 'G', 'C') "
	_cFiltro += " AND ( SF2.F2_EST <> '" + _cEstFil + "'" + " or (SF2.F2_EST = '" +_cEstFil + "'  AND  SA2.A2_EST <> '"+ _cEstFil + "' ) ) "
ElseIf _cEstFil $ ('MG/ES' )
	//_cFiltro += " AND ( SF2.F2_EST <> %exp:_cEstFil%  or (SF2.F2_EST = %exp:_cEstFil%  AND  SA2.A2_EST <> %exp:_cEstFil% ) ) "
	_cFiltro += " AND ( SF2.F2_EST <> '" + _cEstFil + "'" + " or (SF2.F2_EST = '" + _cEstFil + "'  AND  SA2.A2_EST <> '"+ _cEstFil + "' ) ) "	
Else
	_cFiltro += " AND ((SA2.A2_I_CLASS IN ('T', 'G', 'C') AND SA2.A2_EST <> '"+_cEstFil+"') OR SA2.A2_I_CLASS = 'A')"
	_cFiltro += " AND SF2.F2_EST <> '" + _cEstFil + "' "
EndIf          
   
_cFiltro += "%"  

  TRFunction():New(oSecDados:Cell("F2_I_FRET"),NIL,"SUM",oBreakFil,NIL,NIL,NIL,.F.,.T.)
  TRFunction():New(oSecDados:Cell("vlrICMS") ,NIL,"SUM",oBreakFil,NIL,NIL,NIL,.F.,.T.)

//Executa query para consultar Dados
BEGIN REPORT QUERY oSecFil
 
	BeginSql Alias "QRY"
	
		SELECT A.*, 
		       Case
		         WHEN F2_TIPO NOT IN ('B', 'D') THEN
		          (SELECT RTRIM(A1_MUN) || '-' || A1_EST
		             FROM %Table:SA1%
		            WHERE SA1010.D_E_L_E_T_ = ' '
		              AND A1_COD = F2_CLIENTE
		              AND A1_LOJA = F2_LOJA)
		         Else
		          (SELECT RTRIM(A2_MUN) || '-' || A2_EST
		             FROM %Table:SA2%
		            WHERE SA2010.D_E_L_E_T_ = ' '
		              AND A2_COD = F2_CLIENTE
		              AND A2_LOJA = F2_LOJA)
		       END MUN_EST
		  FROM (SELECT SF2.F2_FILIAL,
		               SF2.F2_EMISSAO,
		               SF2.F2_TIPO,
		               SF2.F2_DOC,
		               SF2.F2_SERIE,
		               SF2.F2_CLIENTE,
		               SF2.F2_LOJA,  
		               SF2.F2_EST,
		               SF2.F2_I_CTRA,
		               SF2.F2_I_LTRA,
		               SA2.A2_NOME,
					   RTRIM(SA2.A2_MUN) || '-' || SA2.A2_EST UFTRANSP,
					   SA2.A2_EST,
		               SA2.A2_I_CLASS,
		               DA4.DA4_COD,
		               DA4.DA4_NOME,
		               SF2.F2_I_FRET,
					   SA2.A2_I_F1298 FIM1298
//					   Case SA2.A2_I_F1298 WHEN ' ' THEN '20491231' Else SA2.A2_I_F1298 END AS FIM1298
		          FROM %Table:SF2% SF2, %Table:DA4% DA4, %Table:SA2% SA2
		         WHERE SF2.D_E_L_E_T_ = ' '
		           AND DA4.D_E_L_E_T_ = ' '
		           AND SA2.D_E_L_E_T_ = ' '
		           AND SF2.F2_FILIAL = %xFilial:SF2%
		           AND SF2.F2_I_MOTOR = DA4.DA4_COD
		           AND SF2.F2_I_CTRA = SA2.A2_COD
		           AND SF2.F2_I_LTRA = SA2.A2_LOJA
		           AND SF2.F2_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
		           AND SF2.F2_CARGA <> ' '
		           %exp:_cFiltro%
		           ) A WHERE F2_EMISSAO > FIM1298
		 ORDER BY F2_FILIAL, F2_EMISSAO, F2_DOC, F2_SERIE
  
	EndSql 

END REPORT QUERY oSecFil

oSecDados:SetParentQuery()
oSecDados:SetParentFilter( {|cParam| cFilAnt == cParam } , {|| cFilAnt } )
oSecFil:Print(.T.)

Return 
                           
/*
===============================================================================================================================
Programa----------: ROMS021AL
Autor-------------: Jerry
Data da Criacao---: 29/09/2021
Descrição---------: Função para tratar Aliquota de ICMS
Parametros--------:  
Retorno-----------: _nVlrICMS - Aliquota + Valor do ICMS do Frete
===============================================================================================================================
*/
Static Function ROMS021AL()
Local _nVlrICMS := 0
Local _nAlqInGo	:= GetMV( "IT_ALQR021")

If _cEstFil = 'GO' .And. QRY->F2_EST = 'GO' //Goias	
	If AllTrim(QRY->A2_EST) <> AllTrim(_cEstFil)
		_nVlrICMS := ( QRY->F2_I_FRET * _nAlqInGo )		 /// 0.17
	Else
		_nVlrICMS := ( QRY->F2_I_FRET * IIf( _cEstFil $ _cEstDif .And. !( QRY->F2_EST $ _cEstDif ) , 0.07 , 0.12 ) )
	EndIf		 
Else 
	_nVlrICMS := ( QRY->F2_I_FRET * IIf( _cEstFil $ _cEstDif .And. !( QRY->F2_EST $ _cEstDif ) , 0.07 , 0.12 ) )	
EndIf 

Return _nVlrICMS
