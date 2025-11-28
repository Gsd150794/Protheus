/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Carvalho|29/07/2016| Chamado 16419. Ajuste de gravação do campo D3_I_OBS.
André Carvalho|03/04/2017| Chamado 19575. Ajuste de gravação do campo D3_I_OBS.
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M185CAMP
Autor-------------: Talita Teixeira
Data da Criacao---: 11/03/2013
Descrição---------: Ponto de entrada responsavel pelo preenchimento do campo D3_I_NUMCP de acordo com o numero da Solicitação
        						do armazem na baixa da pré requisição.Chamado 2729
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function M185CAMP()

Local _aArea 	:= FWGetArea()
Local _aAreaSCP:= SCP->(FWGetArea())
Local cCampo  := ParamIXB[1]  //-- Nome do campo que esta sendo processado
Local z       := ParamIXB[2]  //-- Numero da linha posicionada no aCols
  								  //-- Dimensão de posição do array A185Dados ('Array onde esta os movimentos a serem gerados')
Local i       := ParamIXB[4]  //-- Dimensão do campo dentro do aCols.             
Local nX     := ParamIXB[3]

DBSelectArea("SCP")
SCP->(DBSetOrder(2))

If cCampo == "D3_I_NUMCP" 
  SCP->(DBSeek(xFilial("SCP")+aCols[z][1]+cNumSa))
  aCols[z][i]:= SCP->CP_NUM  
EndIf   

If cCampo == "D3_I_OBS" // validação para que o conteudo do campo CP_OBS seja mostrado na baixa - Chamado:3168  
  SCP->(DBSeek(xFilial("SCP")+aCols[z][1]+cNumSa+a185dados[nx,3]))//CP_FILIAL+CP_PRODUTO+CP_NUM+CP_ITEM    
  aCols[z][i]:= SCP->CP_OBS   
EndIf    

If cCampo == "D3_I_MOTIV" // validação para que seja carregado o conteudo do campo CP_I_MOTIV na tela de baixa. Chamado: 3291	
  SCP->(DBSeek(xFilial("SCP")+aCols[z][1]+cNumSa))//CP_FILIAL+CP_PRODUTO+CP_NUM+CP_ITEM    
  aCols[z][i]:= SCP->CP_I_MOTIV  
EndIf     

SCP->(DBCloseArea())
SCP->(FWRestArea(_aAreaSCP))
FWRestArea(_aArea)

Return
