/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Erich Buttner |17/09/2013| Chamado 4251. Declarada a varivel _cGrupCom como sendo local.
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT650C1
Autor-------------: Tiago Correa Castro
Data da Criacao---: 25/10/2008
Descrição---------: Ponto de Entrada apos a gravacao de cada item do SC1 gerado por uma Ordem de Producao(OP).
					Localização: Este P.E. esta localizado na função A650GravC1 (Grava Solicitação de Compras)
					Em que Ponto: É chamado apos gravar os dados no arquivo SC1 (Solic. de Compras).
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT650C1

Local _aArea 	:=	FWGetArea()
Local _cCodAprv	:=	AllTrim(GetMv("IT_APSCOP"))//Devera ser criado o parametro IT_APSCOP para cada filial que ira emitir Ordem de Producao, pois esse parametro que define o possivel aprovador da solicitacao de compra. 
Local _cProd	:=	SC1->C1_PRODUTO
Local _cGrupCom := "" // ALTERADO POR ERICH BUTTNER DIA 17/09/13 - DECLARADO A VARIAVEL
	
If Empty(_cCodAprv)
	MsgAlert("Erro na Geração das Solicitações de Compra" + Chr(13)+ Chr(13)+ "Não foi definido Aprovador para as Solicitações geradas por essa Ordem de Producao - Parametro IT_APSCOP vazio para essa filial. Solicite Ajuda do Administrador.","MT650C1001")
EndIf
	
//Tratamento para buscar o Grupo de Compras da tabela SBZ010(Indicadores de Produto)
DBSelectArea("SBZ")
SBZ->(DBSetOrder(1))//BZ_FILIAL+BZ_COD
If SBZ->(DBSeek(xFilial("SBZ")+_cProd))
	_cGrupCom	:=	SBZ->BZ_I_GRUPC
EndIf

//Grava dados na SC1 gerada por uma OP.
SC1->(RecLock("SC1",.F.))
SC1->C1_GRUPCOM	:= 	_cGrupCom 
SC1->C1_I_CODAP	:=	_cCodAprv
SC1->C1_I_CDSOL :=	FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
SC1->C1_I_DTINC :=	Date() 
SC1->C1_I_HRINC :=	Time() 
SC1->(MSUnLock())
	
FWRestArea(_aArea)

Return
