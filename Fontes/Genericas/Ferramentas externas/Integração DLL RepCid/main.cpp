//===========================================================================================================================
// ATUALIZACOES SOFRIDAS DESDE A CONSTRU�AO INICIAL
//===========================================================================================================================
//Autor        |    Data    |                              Motivo      
//---------------------------------------------------------------------------------------------------------------------------|
//Josu� Prestes| 18/08/2017 | Revis�o de conex�o e mensagens - Chamado 20400 
//===========================================================================================================================
//
//===========================================================================================================================

#Include <stdio.h>
#Include <ctime>
#Include <iostream>
#Include <fstream>
#Include <string>



#pragma region Includes
#Include <stdio.h>
#Include <comutil.h> 
#pragma endregion

//===================================================================================================================================
//Programa------------: integra.exe
//Autor------------ - : Josu� Danich Prestes
//Data da Criacao-- - : 20/12/2016
//===================================================================================================================================
//Descri��o-------- - : Rotina de integra��o com repcid.dll
//===================================================================================================================================
//Parametros-------- : argv[1] - IP do equipamento que sera conectado
//                     argv[2] - Opera��o a ser executada - 1 L� AFD, 2 Inclui/Altera funcionario, 3 Deleta funcionario, 4 apaga rfid
//                     argv[3] - Para argv[2] = 2 ou argv[2] = 3 ser� o PIS do funcionario 
//								 Para argv[2] = 4 sera o rfid a ser limpo do rel�gio			
//                               
//===================================================================================================================================
//Retorno---------- - : Nenhum
//===================================================================================================================================

#pragma region Import the type library

// Importing mscorlib.tlb is necessary for .NET components
// see: 
//  http://msdn.microsoft.com/en-us/library/s5628ssw.aspx
#import "mscorlib.tlb" raw_interfaces_only				\
	high_property_prefixes("_get","_put","_putref")		\
	rename("ReportEvent", "InteropServices_ReportEvent")
using namespace mscorlib;

#import "libid:2e6553ec-aa8b-40cc-aab3-7c5314781d63" \
	no_namespace \
	named_guids

#pragma endregion




int main(int argc, char *argv[])
{

	if (argc > 2)
	{


		HRESULT hr = S_OK;

		// Initializes the COM library on the current thread and identifies the
		::CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);

		// CreateInstance
		IRepCidPtr spRepCidObj;
		hr = spRepCidObj.CreateInstance(__uuidof(RepCid));
		if (FAILED(hr))
		{
			wprintf(L"IRepCidObjectPtr::CreateInstance falhou. Erro: 0x%08lx\n", hr);
			return hr;
		}

		//=======================================================================================
		//Bloco de leitura da AFD
		//=======================================================================================
		if (strcmp(argv[2], "1") == 0) 
		{

			{

					int res = 0;
					do
					{

						char* IP = (char*)argv[1];

						ErrosRep err;
						//wprintf(L"Conectando com o REP pela porta 1818...");
						err = spRepCidObj->Conectar(IP, 1818, 0);
						if (err != ErrosRep_OK)
						{
							//N�o conseguiu conectar ao rep antigo, tenta conectar ao rep novo
							//wprintf(L"Conectando com o REP pela porta 443...");
							spRepCidObj->iDClassPort = 443;
							err = spRepCidObj->iDClass_Conectar(IP, "admin", "admin");

							if (err != ErrosRep_OK)
							{
								break;
							}
						}

						//atualiza data e hora em toda a comunica��o
						time_t t = time(NULL);
						tm* timePtr = localtime(&t);

						VARIANT_BOOL _lachou;

						spRepCidObj->GravarDataHora(1900 + timePtr->tm_year,
							1 + timePtr->tm_mon,
							timePtr->tm_mday,
							timePtr->tm_hour,
							timePtr->tm_min,
							timePtr->tm_sec,
							&_lachou);


						
						long long num_afd = atoll(argv[3]);
						bool lachou;

						lachou = spRepCidObj->BuscarAFD(num_afd);

						if (lachou)
						{
							time_t t = time(NULL);
							tm* timePtr = localtime(&t);

							//cabecalho do arquivo de ponto
							wprintf(L"0000000001101257995000303000000000000GOIASMINAS INDUSTRIA DE LATICINIOS LTDA000140037700013510101200101012030");
							
							if (timePtr->tm_mday < 10)
							{
								printf("%i", 0);
							}
							printf("%i", timePtr->tm_mday);
							
							if (timePtr->tm_mon < 11)
							{
								printf("%i", 0);
							}
							printf("%i", 1 + timePtr->tm_mon);
							
							printf("%i",1900+timePtr->tm_year);
							
							
							BSTR linha;

							do
							{

								lachou = spRepCidObj->LerAFD(&linha);

								if (lachou)
								{
									printf("%S", linha);
								}

							} while (lachou);

						}

					} while (0);

					res = spRepCidObj->Desconectar();

				}

				// Uninitialize COM for this thread
				::CoUninitialize();

				return 0;
			
		}

		//=======================================================================================
		//Bloco de Cria/altera funcionario
		//=======================================================================================
		if (strcmp(argv[2], "2") == 0) 
		{

			{

					int res = 0;
					do
					{

		
						wprintf(L"Conectando com o REP pela porta 1818...");

						char* IP = (char*)argv[1];

						ErrosRep err;
						err = spRepCidObj->Conectar(IP, 1818, 0);
						if(err != ErrosRep_OK)
						{
							//N�o conseguiu conectar ao rep antigo, tenta conectar ao rep novo
							wprintf(L"Conectando com o REP pela porta 443...");
							spRepCidObj->iDClassPort = 443;
							err = spRepCidObj->iDClass_Conectar(IP, "admin", "admin");

							if (err != ErrosRep_OK)
							{
								wprintf(L"Falha de conexao...");
								break;
							}
						}

						wprintf(L" OK\n\n");

						//atualiza data e hora em toda a comunica��o
						time_t t = time(NULL);
						tm* timePtr = localtime(&t);

						VARIANT_BOOL _lachou;

						spRepCidObj->GravarDataHora(1900 + timePtr->tm_year,
							1 + timePtr->tm_mon,
							timePtr->tm_mday,
							timePtr->tm_hour,
							timePtr->tm_min,
							timePtr->tm_sec,
							&_lachou);


						//Le arquivo de funcionarios
						FILE *arq;
						char Linha[100];
						char *result;
						int i;
						long long pis;
						BSTR  nome;
						BSTR cpis;
						int codigo;
						BSTR  senha;
						BSTR  barras;
						int rfid;
						int privil;
						VARIANT_BOOL lachou;
	
						// Abre um arquivo TEXTO para LEITURA
						arq = fopen("integra.txt", "rt");
						if (arq == NULL)  // Se houve erro na abertura
						{
							printf("Problemas na abertura do arquivo\n");
							break;
						}
						i = 1;
						while (!feof(arq))
						{
							// L� uma linha (inclusive com o '\n')
							result = fgets(Linha, 100, arq);  // o 'fgets' l� at� 99 caracteres ou at� o '\n'
							
							if (result)  // Se foi poss�vel ler
							{
								strtok(Linha, "\n");
								if (i == 1)
								{
									pis = atoll(Linha);
									cpis = _com_util::ConvertStringToBSTR(Linha);
									
								}

								if (i == 2)
								{
									nome = _com_util::ConvertStringToBSTR(Linha);
									
								}

								if (i == 3)
								{
									codigo = atoi(Linha);
									
								}

								if (i == 4)
								{
									senha = _com_util::ConvertStringToBSTR(Linha);
								}

								if (i == 5)
								{
									barras = _com_util::ConvertStringToBSTR(Linha);
								}

								if (i == 6)
								{
									rfid = atoi(Linha);
								}

								if (i == 7)
								{
									int privil = atoi(Linha);
									
									i = 1;

									//Antes de gravar o usu�rio se rfid for maior
									// que zero deve verificar se n�o tem outro
									// funcionario com mesmo rfid e zerar o mesmo

									long num_usuarios;
									spRepCidObj->CarregarUsuarios(VARIANT_FALSE, &num_usuarios);

									__int64 _pis;
									BSTR _nome, _senha, _barras;
									long _codigo, _rfid, _privilegios, _ndig;
									VARIANT_BOOL _lachou;

									while (spRepCidObj->LerUsuario(&_pis, &_nome, &_codigo, &_senha, &_barras, &_rfid, &_privilegios, &_ndig) == VARIANT_TRUE)
									{
										if (rfid == _rfid && _pis != pis)
										{
											wprintf(L"Funcionario tem mesmo rfid que sera gravado e tera o rfid zerado:\n");
											wprintf(L"    %12lld %s\n", pis, nome, rfid);

											_rfid = 0;

											spRepCidObj->GravarUsuario(
												_pis,
												_nome,
												_codigo,
												_senha,
												_barras,
												_rfid,
												_privilegios,
												&_lachou
												);


											if (_lachou)
											{
												printf("Limpou com sucesso\n");
											}
											else
											{
												printf("Nao limpou\n");
											}

										}
									}


									spRepCidObj->GravarUsuario(
													pis,
													nome,
													codigo,
													senha,
													barras,
													rfid,
													privil,
													&lachou
													);


									if (lachou)
									{
										printf("Gravou com sucesso - ");
										wprintf(L"    %12lld %s\n", pis, nome, rfid);
									}
									else
									{
										printf("Nao gravou - ");
										wprintf(L"    %12lld %s\n", pis, nome, rfid);
									}


								}
								else
								{
									
									i++;
								}
								
								

							}
							
						}
						fclose(arq);

						
					wprintf(L" OK\n\n");

					} while (0);
					res = spRepCidObj->Desconectar();

				// Uninitialize COM for this thread
				::CoUninitialize();

				return 0;
			}

		}

		//=======================================================================================
		//Bloco de Exclui funcionario
		//=======================================================================================
		if (strcmp(argv[2], "3") == 0) 
		{

				int res = 0;
				do
				{
					wprintf(L"Conectando com o REP pela porta 1818...");

					char* IP = (char*)argv[1];

					ErrosRep err;
	
					err = spRepCidObj->Conectar(IP, 1818, 0);
					if (err != ErrosRep_OK)
					{
						//N�o conseguiu conectar ao rep antigo, tenta conectar ao rep novo
						wprintf(L"Conectando com o REP pela porta 443...");
						spRepCidObj->iDClassPort = 443;
						err = spRepCidObj->iDClass_Conectar(IP, "admin", "admin");

						if (err != ErrosRep_OK)
						{
							break;
						}
					}

					wprintf(L" OK\n\n");

					//atualiza data e hora em toda a comunica��o
					time_t t = time(NULL);
					tm* timePtr = localtime(&t);

					VARIANT_BOOL lachou;
	
					spRepCidObj->GravarDataHora(1900 + timePtr->tm_year,
					                              1 + timePtr->tm_mon,
												  timePtr->tm_mday,
												  timePtr->tm_hour,
												  timePtr->tm_min,
												  timePtr->tm_sec,
												  &lachou);
						
					
					long long pis = atoll(argv[3]);
					
					spRepCidObj->RemoverUsuario( pis,	&lachou	);

					if (lachou)
					{
						printf("Excluiu com sucesso - ");
						wprintf(L"    %12lld %s\n", pis);

					}
					else
					{
						printf("Nao gravou");
						wprintf(L"    %12lld %s\n", pis);
					}



				} while (0);


				long num_usuarios;
				spRepCidObj->CarregarUsuarios(VARIANT_FALSE, &num_usuarios);
				wprintf(L"Encontrou %d usuarios no REP:\n", num_usuarios);

				__int64 pis;
				BSTR nome, senha, barras;
				long codigo, rfid, privilegios, ndig;

				while (spRepCidObj->LerUsuario(&pis, &nome, &codigo, &senha, &barras, &rfid, &privilegios, &ndig) == VARIANT_TRUE)
				{
					wprintf(L"    %12lld %s\n", pis, nome);
				}


				res = spRepCidObj->Desconectar();


			// Uninitialize COM for this thread
			::CoUninitialize();



			return 0;
		}

		//=======================================================================================
		//Bloco de Exclui rfid da base do rel�gio
		//=======================================================================================
		if (strcmp(argv[2], "4") == 0)
		{
			printf("Exclui rfid\n");

			wprintf(L"Conectando com o REP pela porta 1818...");

			char* IP = (char*)argv[1];

			ErrosRep err;

			err = spRepCidObj->Conectar(IP, 1818, 0);
			if (err != ErrosRep_OK)
			{
				//N�o conseguiu conectar ao rep antigo, tenta conectar ao rep novo
				wprintf(L"Conectando com o REP pela porta 443...");
				spRepCidObj->iDClassPort = 443;
				err = spRepCidObj->iDClass_Conectar(IP, "admin", "admin");

				if (err != ErrosRep_OK)
				{
					return 0;
				}
			}

			wprintf(L" OK\n\n");

			//atualiza data e hora em toda a comunica��o
			time_t t = time(NULL);
			tm* timePtr = localtime(&t);

			VARIANT_BOOL lachou;

			spRepCidObj->GravarDataHora(1900 + timePtr->tm_year,
				1 + timePtr->tm_mon,
				timePtr->tm_mday,
				timePtr->tm_hour,
				timePtr->tm_min,
				timePtr->tm_sec,
				&lachou);



			long num_usuarios;
			spRepCidObj->CarregarUsuarios(VARIANT_FALSE, &num_usuarios);
			wprintf(L"Encontrou %d usuarios no REP:\n", num_usuarios);

			__int64 pis;
			BSTR nome, senha, barras;
			long codigo, rfid, privilegios, ndig;
			

			while (spRepCidObj->LerUsuario(&pis, &nome, &codigo, &senha, &barras, &rfid, &privilegios, &ndig) == VARIANT_TRUE)
			{
				if (atoi(argv[3]) == rfid)
				{
					wprintf(L"    %12lld %s\n", pis, nome, rfid);

					rfid = 0;

					spRepCidObj->GravarUsuario(
						pis,
						nome,
						codigo,
						senha,
						barras,
						rfid,
						privilegios,
						&lachou
						);


					if (lachou)
					{
						printf("Gravou com sucesso - ");
						wprintf(L"    %12lld %s\n", pis, nome, rfid);
					}
					else
					{
						printf("Nao gravou - ");
						wprintf(L"    %12lld %s\n", pis, nome, rfid);
					}

				}
			}
		}
		
	}
	else
	{

		printf("Paramentros invalidos, siga a seguinte formatacao");
		wprintf(L"\n\n");
		printf("integra argv[1] argv[2] argv[3] argv[4] argv[5] argv[6] argv[7] argv[8] argv[9]");
		wprintf(L"\n\n");
		printf("argv[1] - IP do equipamento que sera conectado");
		wprintf(L"\n\n");
		printf("argv[2] - Opera��o a ser executada - 1 Le AFD, 2 Inclui/Altera funcionario, 3 Deleta funcionario, 4 Exclui rfid");
		wprintf(L"\n\n");
		printf("argv[3] - Para argv[2] = 2 ou argv[2] = 3  PIS do funcionario");
		wprintf(L"\n\n");
		printf("argv[3] - Para argv[2] = 4 sera o rfid a ser limpo do rel�gio");
		wprintf(L"\n\n");
		
		return 0;
	}

}




