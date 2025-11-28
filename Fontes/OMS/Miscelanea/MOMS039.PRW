/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor            |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 10/01/2019 | Incluido update de SZW para pedidos importados - Chamado 27639
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 26/02/2019 | Ajuste de execução via schedule - Chamado 28236
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 05/04/2019 | Ajuste de data de cadastro na afa190 - Chamado 28792 
 -------------------------------------------------------------------------------------------------------------------------------
 Jonathan         | 02/10/2020 | Limpeza de viagens finalizadas por parâmetro de filiais - Chamado 34307 
 ------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 10/02/2021 | Correcao do error.log no console.log. Chamado 35598
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TopConn.ch"  

/*
===============================================================================================================================
Programa----------: MOMS039
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/09/2018
===============================================================================================================================
Descrição---------: Schedule de manutenção diária de tabelas - Chamado 26331 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS039()

Local _ddtlimite := date()-u_itgetmv("ITARQMT",90)

If U_ITMsg("Realiza manutenção diária de tabelas?","Atenção","Registros RDC anteriores à " + DToC(_ddtlimite) + " serão apagados! - Pedidos do portal de represntante terão status atualizado - Viagens finalizadas serão limpas do painel RDC",3,2,2)

	FWMsgRun(,{|oproc| U_MOMS039T(.T.,oproc)},"Aguarde processamento...", "Aguarde processamento...")
	
Else

	U_ITMsg("Processo cancelado!","Atenção",,1)

EndIf


Return

/*
===============================================================================================================================
Programa----------: MOMS039T
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/09/2018
===============================================================================================================================
Descrição---------: Processamento de limpeza de tabelas de muro do RDC - Chamado 26331 
===============================================================================================================================
Parametros--------: _lshow - Processando com tela de usuário?
					oproc - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS039T(_lshow,oproc)

Local _atabelas := {"ZFU","ZFH","ZFI","ZFJ","ZFK","ZFL","ZFN","ZFO","ZFP","ZFQ","ZFR","ZFV","ZG4","ZG0"}
Local _nI := 1
Local _ddtlimite := ""

Default _lshow := .F.
Default oproc := nil


If !_lshow

	//Monta ambiente
	u_itconout( 'Abrindo o ambiente...' )
   
	RPCSetType(3)
	RpcSetEnv( "01" , '01' ,,,"COM", "SCHEDULE_MANUT_TABELAS" , {'ZP1','SRA'} )
	Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
	
EndIf

//========================================================================================
//Limpa registros antigos das tabelas de muro RDC
//========================================================================================

_ddtlimite := date()-u_itgetmv("ITARQMT",90)
u_itconout("Iniciando limpeza de tabelas de muro com datas anteriores à " + DToC(_ddtlimite) + "...")

For _nI := 1 to Len(_atabelas)

	If _lshow
	
		oproc:cCaption := ("Limpando dados anteriores à "  + DToC(_ddtlimite) + " para a tabela " + _atabelas[_nI] + "...")
		ProcessMessages()
		
	EndIf
	
	u_itconout("Limpando dados anteriores à "  + DToC(_ddtlimite) + " para a tabela " + _atabelas[_nI] + "...")
	
	_cQry := " Delete from  " + _atabelas[_nI] + "010 where ("  + _atabelas[_nI] + "_SITUAC = 'P' OR "  + _atabelas[_nI] + "_SITUAC = 'E')
	_cQry += " AND " +  _atabelas[_nI] + "_DATA < '" + DToS(_ddtlimite) + "'"
		
	_nres := TCSqlExec(_cQry)
	
	If _nres >= 0
	
		u_itconout("Limpeza bem sucedida de dados anteriores à "  + DToC(_ddtlimite) + " para a tabela " + _atabelas[_nI] + "...")
		
	Else
	
		u_itconout("Falhou limpeza de dados anteriores à "  + DToC(_ddtlimite) + " para a tabela " + _atabelas[_nI] + "...")
	
	EndIf

Next

//==================================================================
//Realiza ajuste de status de tabela de portal do representante
//==================================================================
u_itconout("Realizando ajuste de status de pedidos do portal já importados...")

	If _lshow
	
		oproc:cCaption := ("Realizando ajuste de status de pedidos do portal já importados...")
		ProcessMessages()
		
	EndIf

	
_cQry := "update " + retsqlname("SZW") + " set zw_status = 'I' where D_E_L_E_T_ = ' ' and zw_numped <> ' ' and zw_status = 'L'"
		
_nres := TCSqlExec(_cQry)
	
If _nres >= 0
	
	u_itconout("Ajuste bem sucedido de status de pedidos do portal já importados...")
		
Else
	
	u_itconout("Falhou ajuste de status de pedidos do portal já importados...")
	
EndIf

//===================================================================================================================================
//Limpeza de viagens finalizadas dos painéis RDC
//===================================================================================================================================
_cFil := u_itgetmv("IT_FILLIMP")

_cQuery :=  "     SELECT codfil, numero AS viagem "
_cQuery +=  "     FROM rdcitl.afa037 a "
_cQuery +=  "     WHERE    situac <> 5 "
_cQuery +=  "              AND (dtcheg IS NULL OR dtrica IS NULL) "
_cQuery +=  "              AND nrsoli IS NOT NULL "
_cQuery +=  "              AND EXISTS "
_cQuery +=  "                     (SELECT 'x' "
_cQuery +=  "                        FROM rdcitl.afa190 b "
_cQuery +=  "                       WHERE     b.codfil = a.codfil "
_cQuery +=  "                             AND b.numero = a.numero "
_cQuery +=  "                             AND b.libnfc = 'N' "
_cQuery +=  "                             AND b.libcar = 'N' "
_cQuery +=  "                             AND b.pageno IS NULL "
_cQuery +=  "                             AND b.pagede IS NULL) "
_cQuery +=  "              AND EXISTS "
_cQuery +=  "                     (SELECT 'x' "
_cQuery +=  "                        FROM dak010 dak "
_cQuery +=  "                       WHERE     dak_filial = LPAD (codfil, 2, '0') "
_cQuery +=  "                             AND dak_cod = LPAD (nrsoli, 6, '0') "
_cQuery +=  "                             AND dak_feznf = '1' "
_cQuery +=  "                             AND dak.d_e_l_e_t_ = ' ') "
_cQuery +=  "     AND a.codfil IN " + StrTran(FormatIn(_cFil, ";"), "'","")
 
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , "TMP" , .F. , .T. )
	
TMP->( DBGoTop() )


While TMP->(!Eof())

	u_itconout("Limpando painéis para viagem - " + AllTrim(StrZero(TMP->CODFIL,2)) + " - " + AllTrim(StrZero(TMP->VIAGEM,6)))
	
	_cQry := "UPDATE rdcitl.tga300 SET status = 5, stctrl = 7 WHERE     filialviagem = " + AllTrim(Str(TMP->CODFIL)) + " AND nrviagem = " + AllTrim(Str(TMP->VIAGEM))
	
	_nres1 := TCSqlExec(_cQry)
	
	//Carrega dados da afa190 para montar data e hora de cadastro
	
	_cQuery :=  "     SELECT datcad, hrcad "
	_cQuery +=  "     FROM rdcitl.afa190  "
	_cQuery +=  "     WHERE     codfil = " + AllTrim(Str(TMP->CODFIL)) + " AND numero = " + AllTrim(Str(TMP->VIAGEM))

	DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , "TMP2" , .F. , .T. )
	
	If TMP2->(!Eof())

		TMP2->( DBGoTop() )

		_cdate := "'" + SubStr(DToS(TMP2->DATCAD),1,4)+"/"+SubStr(DToS(TMP2->DATCAD),5,2)+"/"+SubStr(DToS(TMP2->DATCAD),7,2) + " " + tmp2->hrcad + ":00'"+", 'YYYY/MM/DD HH24:MI:SS'
	
		DBSelectArea("TMP2")
		TMP2->(DBCloseArea())

	Else

		u_itconout("Limpeza e painéis RDC para viagem - " + AllTrim(StrZero(TMP->CODFIL,2)) + " - " + AllTrim(StrZero(TMP->VIAGEM,6)) + " falhou..." )
		TMP->(DBSkip())
		Loop

	EndIf

	_cqry := "UPDATE rdcitl.afa190 SET dtfira = TO_DATE("+ _cdate + "), datram = TO_DATE("+ _cdate + "), pageno = 999, pagede = 999, codloc = 1, codram = 1, libcar = 'S', libnfc = 'S' "
	_cQry += " WHERE     codfil = " + AllTrim(Str(TMP->CODFIL)) + " AND numero = " + AllTrim(Str(TMP->VIAGEM))

	_nres2 := TCSqlExec(_cQry)
		
	_cQry := "UPDATE rdcitl.afa037 SET dtcheg = datcad, hrcheg = hrcad, dtrica = datcad, hrrica = hrcad "
	_cQry += " WHERE     codfil = " + AllTrim(Str(TMP->CODFIL)) + " AND numero = " + AllTrim(Str(TMP->VIAGEM))
	
	_nres3 := TCSqlExec(_cQry)
	
	If _nres1 >= 0 .And. _nres2 >= 0 .And. _nres3 >= 0
	
		u_itconout("Limpeza e painéis RDC para viagem - " + AllTrim(StrZero(TMP->CODFIL,2)) + " - " + AllTrim(StrZero(TMP->VIAGEM,6)) + " bem sucedida..." )
		
	Else
	
		u_itconout("Limpeza e painéis RDC para viagem - " + AllTrim(StrZero(TMP->CODFIL,2)) + " - " + AllTrim(StrZero(TMP->VIAGEM,6)) + " falhou..." )
	
	EndIf
		
	TMP->(DBSkip())
	
EndDo

DBSelectArea("TMP")
TMP->(DBCloseArea())

U_ITMsg("Processo finalizado","Atenção",,2)

u_itconout("Processo de ajuste de tabelas de integração completado.")

Return

/*
===============================================================================================================================
Programa----------: MOMS039P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/09/2018
===============================================================================================================================
Descrição---------: Chamada de processamento via schedule
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS039P()

U_MOMS039T(.F.,NIL)

Return
