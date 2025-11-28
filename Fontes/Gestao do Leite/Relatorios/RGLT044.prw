/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |22/12/2015| Chamado 13062. Tratativa na cláusula "ORDER BY" para remover a referência numérica
Lucas Borges  |23/08/2019| Chamado 30185. Modificada validação de acesso aos setores
Lucas Borges  |11/02/2025| Chamado 49877. Removido tratamento sobre a versão do Mix
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "Report.ch"

/*
===============================================================================================================================
Programa--------: RGLT044
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/07/2010
Descrição-------: Relatório utilizado para exibir os dados de litragem e valor total bruto pago aos produtores
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT044()

Private cPerg		:= "RGLT044"
Private QRY1		:= Nil
Private oReport		:= Nil
Private oSecFilial	:= Nil
Private oSecDtMix	:= Nil
Private oSecDados	:= Nil
Private cNomeMes	:= "" //Armazena o nome do mes corrente para que seja utilizada na impressao da quebra
Private cNomeFil	:= ""

Pergunte( cPerg , .F. )

DEFINE REPORT oReport NAME cPerg TITLE "Dados Produtor" PARAMETER cPerg ACTION {|oReport| RGLT044PRT(oReport)} Description "Este relatório emitirá os dados do produtor juntamente com a sua litragem do mix e valor brunto pago ao mesmo no referido mix."

oReport:SetLandscape() //Seta Padrao de impressao como Paisagem
oReport:SetTotalInLine(.F.)              
oReport:nFontBody	:= 10
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 50 // Define a altura da linha.
oReport:SetMsgPrint('AGUARDE OS DADOS DO RELATORIO ESTAO SENDO PROCESSADOS')//mensagem exibida no momento da impressao

DEFINE Section oSecFilial OF oReport TITLE "Dados_Filial" TABLES "SE2" 

DEFINE CELL NAME "E2_FILIAL"    OF oSecFilial ALIAS "SE2" TITLE "Filial"    
DEFINE CELL NAME "NOMFIL"	    OF oSecFilial ALIAS ""    TITLE "Filial"    SIZE 40 BLOCK{|| QRY1->E2_FILIAL + ' - ' + FWFilialName(cEmpAnt,QRY1->E2_FILIAL,1)}

oSecFilial:SetLinesBefore(2) 
oSecFilial:SetLineStyle(.T.) 
oSecFilial:Cell("E2_FILIAL"):Disable()                                                                               

DEFINE Section oSecDtMix  OF oSecFilial TITLE "Dados_Data" TABLES "SE2"

DEFINE CELL NAME "MESANO"	   	OF oSecDtMix ALIAS ""    TITLE "Mês/Ano"              SIZE 40 BLOCK{|| MesExtenso( Val( SubStr( QRY1->DTMIX , 5 , 2 ) ) ) + '/' + SubStr(QRY1->DTMIX,1,4)}               
DEFINE CELL NAME "QBRMESANO"  	OF oSecDtMix ALIAS ""    TITLE ""                     SIZE 40 BLOCK{|| QRY1->E2_FILIAL + SubStr(QRY1->DTMIX,5,2) + '/' + SubStr(QRY1->DTMIX,1,4)}               

oSecDtMix:Cell("QBRMESANO"):Disable() 

oSecDtMix:SetLineStyle(.T.)                                                                             
oSecDtMix:OnPrintLine({|| cNomeFil := QRY1->E2_FILIAL + '-' + FWFilialName(cEmpAnt,QRY1->E2_FILIAL,1)}) 

DEFINE Section oSecDados OF oSecDtMix TITLE "Dados_Produtor" TABLES "SE2","SA2"

DEFINE CELL NAME "CODPRODUTOR"	  OF oSecDados ALIAS "SA2" TITLE "Cod.Produtor"      	SIZE 20 BLOCK{|| QRY1->E2_FORNECE + '/' + QRY1->E2_LOJA}
DEFINE CELL NAME "A2_NOME"        OF oSecDados ALIAS "SA2" TITLE "Descrição Produtor" 	SIZE 60   
DEFINE CELL NAME "CPF/CGC"        OF oSecDados ALIAS "SA2" TITLE "CPF/CNPJ"             SIZE 25 BLOCK{|| IIf(Len(AllTrim(QRY1->A2_CGC)) == 11,Transform(QRY1->A2_CGC,"@R 999.999.999-99"),Transform(QRY1->A2_CGC,"@R 99.999.999/99999-99"))}
DEFINE CELL NAME "VOLLEITE"       OF oSecDados ALIAS ""    TITLE "Litragem"             SIZE 25 PICTURE "@E 999,999,999,999"
DEFINE CELL NAME "VLRPAGO"        OF oSecDados ALIAS ""    TITLE "Valor Pago"           SIZE 25 PICTURE "@E 999,999,999,999.99"
DEFINE CELL NAME "E2_NUM"         OF oSecDados ALIAS "SE2" TITLE "Nota Fiscal"          SIZE 25 
DEFINE CELL NAME "EMISSAO"        OF oSecDados ALIAS "SE2" TITLE "Emissão"              SIZE 16 BLOCK{|| DToC(QRY1->E2_EMISSAO)}

//Alinhamento de cabecalho
oSecDados:Cell("VOLLEITE"):SetHeaderAlign("RIGHT")  
oSecDados:Cell("VLRPAGO"):SetHeaderAlign("RIGHT")  

oSecDados:SetTotalInLine(.F.)

oSecDados:OnPrintLine({|| cNomeMes := MesExtenso( Val( SubStr( QRY1->DTMIX , 5 , 2 ) ) ) + '/' + SubStr(QRY1->DTMIX,1,4) }) 

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa--------: RGLT044PRT
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 13/07/2010
Descrição-------: Relatório utilizado para exibir os dados de litragem e valor total bruto pago aos produtores
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT044PRT(oReport)

Local _cFiltro	:= "%"
Local _cFilSub	:= ""
Local _aSelFil	:= {}

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLD")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//====================================================================================================
// Define o filtro de acordo com os parametros digitados - Filtra Filial da SF2,SE1,SA1,ZAZ,SA3,ACY
//====================================================================================================
_cFiltro += " AND E2.E2_FILIAL "+ GetRngFil( _aSelFil, "SE2", .T.,)

_cFilSub:=_cFiltro + "%"

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR02) .Or. Empty(MV_PAR02) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND E2.E2_L_SETOR IN "+ FormatIn( AllTrim(MV_PAR02) , ';' )
EndIf
_cFiltro += "%"

//====================================================================================================
// Quebra por Filial + MES + ANO
//====================================================================================================
oBrkMesAno := TRBreak():New( oSecDtMix , oSecDtMix:CELL("QBRMESANO") , "Total Mês/Ano: "+ cNomeMes , .F. )
oBrkMesAno:SetTotalText( {|| "Total Mês/Ano: "+ cNomeMes } )

TRFunction():New( oSecDados:Cell("VOLLEITE") , NIL , "SUM" , oBrkMesAno , NIL , NIL , NIL , .F. , .F. )
TRFunction():New( oSecDados:Cell("VLRPAGO")  , NIL , "SUM" , oBrkMesAno , NIL , NIL , NIL , .F. , .F. )

//====================================================================================================
// Quebra por Filial
//====================================================================================================
oBrkFilial := TRBreak():New( oReport , oSecFilial:CELL("E2_FILIAL") , "Total Filial: "+ cNomeFil , .F. )
oBrkFilial:SetTotalText( {|| "Total Filial: "+ cNomeFil } )

TRFunction():New( oSecDados:Cell("VOLLEITE") , NIL , "SUM" , oBrkFilial , NIL , NIL , NIL , .F. , .T. )
TRFunction():New( oSecDados:Cell("VLRPAGO")  , NIL , "SUM" , oBrkFilial , NIL , NIL , NIL , .F. , .T. )

//====================================================================================================
// Executa query para consultar Dados
//====================================================================================================
BEGIN REPORT QUERY oSecFilial
	BeginSql alias "QRY1"
		SELECT E2.E2_FILIAL, E2.E2_FORNECE, A2.A2_NOME, A2.A2_CGC, E2.E2_LOJA, E2.E2_NUM, E2.E2_EMISSAO, E2.E2_L_MIX,
		       E2.E2_L_SETOR, SUM(E2_VALOR) VLRPAGO,
		       SubStr((SELECT ZLE.ZLE_DTINI
		                FROM %Table:ZLE% ZLE
		               WHERE ZLE.D_E_L_E_T_ = ' '
		                 AND ZLE.ZLE_COD = E2.E2_L_MIX),1, 6) DTMIX,
		       (SELECT SUM(ZLD.ZLD_QTDBOM)
		          FROM %Table:ZLD% ZLD
		         WHERE ZLD.D_E_L_E_T_ = ' '
		           AND ZLD.ZLD_RETIRO = E2.E2_FORNECE
		           AND ZLD.ZLD_RETILJ = E2.E2_LOJA
		           AND E2.E2_FILIAL = ZLD.ZLD_FILIAL 
		           %exp:_cFilSub%
		           AND ZLD.ZLD_DTCOLE BETWEEN
		               (SELECT ZLE.ZLE_DTINI
		                  FROM %Table:ZLE% ZLE
		                 WHERE ZLE.D_E_L_E_T_ = ' '
		                   AND ZLE.ZLE_COD = E2.E2_L_MIX)
		           AND (SELECT ZLE.ZLE_DTFIM
		                  FROM %Table:ZLE% ZLE
		                 WHERE ZLE.D_E_L_E_T_ = ' '
		                   AND ZLE.ZLE_COD = E2.E2_L_MIX)) VOLLEITE
		  FROM %Table:SE2% E2, %Table:SA2% A2
		 WHERE E2.D_E_L_E_T_ = ' '
		   AND A2.D_E_L_E_T_ = ' '
		   AND A2.A2_COD = E2.E2_FORNECE
		   AND A2.A2_LOJA = E2.E2_LOJA
		   AND E2.E2_FORNECE LIKE 'P%'
		   AND E2.E2_PREFIXO IN ('2', '3')
		   AND E2.E2_TIPO = 'NF '
		   %exp:_cFiltro%
		   AND E2.E2_L_MIX BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
		   AND E2.E2_FORNECE BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
		   AND E2.E2_LOJA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
		 GROUP BY E2.E2_FILIAL, E2.E2_FORNECE, E2.E2_LOJA, A2.A2_NOME, A2.A2_CGC, E2.E2_NUM, E2.E2_EMISSAO, E2.E2_L_MIX, E2.E2_L_SETOR
		 ORDER BY E2.E2_FILIAL, SUM(E2.E2_VALOR), E2.E2_FORNECE, E2.E2_LOJA
	EndSql
	
END REPORT QUERY oSecFilial

oSecDtMix:SetParentQuery()
oSecDtMix:SetParentFilter( {|cParam| QRY1->E2_FILIAL + QRY1->DTMIX == cParam } , {|| QRY1->E2_FILIAL + QRY1->DTMIX } )

oSecDados:SetParentQuery()
oSecDados:SetParentFilter( {|cParam| QRY1->E2_FILIAL + QRY1->DTMIX == cParam } , {|| QRY1->E2_FILIAL + QRY1->DTMIX } )

oSecFilial:Print(.T.)

Return
