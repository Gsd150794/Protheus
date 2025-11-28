/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/10/2019| Chamado 29577. Se MV_PAR11 = 1: Considerar campo E5_RECPAG = R, Se não considerar E5_RECPAG = P.
Alex Wallauer |19/03/2020| Chamado 32256. Voltamos a maioria dos filtros.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: F190QRY
Autor-----------: Julio de Paula Paz
Data da Criacao-: 03/12/2018
Descrição-------: Ponto de entrada da rotina relação de baixas. Permite definir condições para a query com base nos parâmetros
                  MV_PAR43 a MV_PAR50. Chamado 27117.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function F190QRY()
Local _cQry := ""

Begin Sequence
   
   If MV_PAR11 == 1   
      _cQry := " EXISTS (SELECT E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA " 
	  _cQry += " FROM "+RetSqlName("SE1")+" PO_SE1 "
      _cQry += " WHERE PO_SE1.E1_FILIAL = SE5.E5_FILIAL  AND PO_SE1.D_E_L_E_T_ = ' ' "
      _cQry += " AND PO_SE1.E1_FILIAL = SE5.E5_FILIAL "
      _cQry += " AND PO_SE1.E1_PREFIXO = SE5.E5_PREFIXO "
      _cQry += " AND PO_SE1.E1_NUM = SE5.E5_NUMERO "
      _cQry += " AND PO_SE1.E1_PARCELA = SE5.E5_PARCELA "
      _cQry += " AND PO_SE1.E1_TIPO = SE5.E5_TIPO "
      _cQry += " AND PO_SE1.E1_CLIENTE = SE5.E5_CLIFOR "
      _cQry += " AND PO_SE1.E1_LOJA = SE5.E5_LOJA "
      _cQry += " AND SE5.E5_RECPAG = 'R' "
   
      //FILTRA GRUPO DE CLIENTES
      If !Empty(MV_PAR43)
         _cQry += " AND PO_SE1.E1_I_GPRVE IN " + FormatIn(MV_PAR43,";")
      EndIf  

      //Filtra Emissao da SE1
      If !Empty(MV_PAR44) .And. !Empty(MV_PAR45)
         _cQry += " AND PO_SE1.E1_EMISSAO BETWEEN '" + DToS(MV_PAR44) + "' AND '" + DToS(MV_PAR45) + "'"
      EndIf
		  	
      //Filtra VENCTO da SE1
      If !Empty(MV_PAR48) .And. !Empty(MV_PAR49)
         _cQry += " AND PO_SE1.E1_VENCTO BETWEEN '" + DToS(MV_PAR48) + "' AND '" + DToS(MV_PAR49) + "'"
      EndIf  
		  	
      //================================================================================
      // Filtro por natureza de operação que deverão ser excluidas do relatório. 
      //================================================================================  
      If ! Empty(MV_PAR50)
         _cQry += " AND PO_SE1.E1_NATUREZ NOT IN " + FormatIn(MV_PAR50,";")
      EndIf	        
      
      _cQry += " ) "
         
   Else
      _cQry := " EXISTS (SELECT E2_FILIAL, E2_PREFIXO , E2_NUM ,E2_PARCELA , E2_TIPO , E2_FORNECE , E2_LOJA 
	  _cQry += " FROM "+RetSqlName("SE2")+" PO_SE2 "
      _cQry += " WHERE PO_SE2.E2_FILIAL = SE5.E5_FILIAL  AND PO_SE2.D_E_L_E_T_ = ' ' "
      _cQry += " AND PO_SE2.E2_FILIAL  = SE5.E5_FILIAL "
      _cQry += " AND PO_SE2.E2_PREFIXO = SE5.E5_PREFIXO "
      _cQry += " AND PO_SE2.E2_NUM     = SE5.E5_NUMERO "
      _cQry += " AND PO_SE2.E2_PARCELA = SE5.E5_PARCELA "
      _cQry += " AND PO_SE2.E2_TIPO    = SE5.E5_TIPO "
      _cQry += " AND PO_SE2.E2_FORNECE = SE5.E5_CLIFOR "
      _cQry += " AND PO_SE2.E2_LOJA    = SE5.E5_LOJA "
      _cQry += " AND SE5.E5_RECPAG = 'P' "
   
      //FILTRA EMISSÃO DA SE2
      If !Empty(MV_PAR44) .And. !Empty(MV_PAR45)
         _cQry += " AND PO_SE2.E2_EMISSAO BETWEEN '" + DToS(MV_PAR44) + "' AND '" + DToS(MV_PAR45) + "'"
      EndIf
		  	
      //Filtra VENCTO da SE2
      If !Empty(MV_PAR48) .And. !Empty(MV_PAR49)
         _cQry += " AND PO_SE2.E2_VENCTO BETWEEN '" + DToS(MV_PAR48) + "' AND '" + DToS(MV_PAR49) + "'"
      EndIf
		  	
      //================================================================================
      // Filtro por natureza de operação que deverão ser excluidas do relatório. 
      //================================================================================  
      If ! Empty(MV_PAR50)
         _cQry += " AND PO_SE2.E2_NATUREZ NOT IN " + FormatIn(MV_PAR50,";")
      EndIf
      
      _cQry += " ) "      
      
   EndIf 
/*	
   If !Empty(MV_PAR46)
      _cQry += " AND SE5.E5_MOTBX IN " + FormatIn(MV_PAR46,";") + " "                                                                                               
   EndIf

   If 'CMP' $ MV_PAR46
      If MV_PAR47 == 1
         _cQry += " AND SubStr(SE5.E5_DOCUMEN,1,3) = 'DCT' "
      ElseIf MV_PAR47 == 2
         _cQry += " AND SubStr(SE5.E5_DOCUMEN,1,3) <> 'DCT' "
      EndIf 
   EndIf	 */

End Sequence

Return _cQry
