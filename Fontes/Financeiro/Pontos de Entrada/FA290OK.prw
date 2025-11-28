/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josue Danich  |27/02/2019| Chamado 28218. Incluida exceção para execução via webservice
=============================================================================================================================== 
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FA290OK
Autor-------------: Talita Teixeira
Data da Criacao---: 05/04/2013
Descrição---------: PE de validação do conteudo preenchido no campo fatura. - Chamado: 3015 
Parametros--------: Nenhum
Retorno-----------: Lógico validando ou não a criação da Fatura
===============================================================================================================================
*/
User Function FA290OK()

Local lRet:= .T.
Local cFat
      
cFat	:= Soma1(GetMv("MV_NUMFATP"))

If cFatura <> cFat .And. !(isincallstack("U_LIBERAC")) 

   	U_ITMsg("Número da fatura alterado.","Atenção",;
	"Para prosseguir não altere o número da fatura.",1)
	lRet:= .F. 

Else
	
	lRet:= .T.

EndIf	 

Return lRet
