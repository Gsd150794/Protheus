/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Talita        |10/06/2013|	Chamado 3254. Incluida validação para que seja carregado o conteudo do campo CP_I_MOTIV na tela de baixa
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT185SD3
Autor-------------: Talita Teixeira
Data da Criacao---: 20/05/2013
Descrição---------: Ponto de entrada responsavel pelo preenchimento do campo D3_I_OBS de acordo com a observação armazenada no
                     campo CP_OBS.Chamado 3168
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar lancamento - .F. = Nao Permite confirmar lancamento
===============================================================================================================================
*/
User Function MT185SD3
      
M->D3_I_OBS:=SCP->CP_OBS
M->D3_I_MOTIV:=SCP->CP_I_MOTIV

Return
