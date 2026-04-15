using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Automation;
using System.Xml;
using System.Threading;

namespace ConfigurarVPN
{
    class Program
    {
        static void Main(string[] args)
        {
            string usuario = "";
            
            if (args.Length > 0)
            {
                usuario = args[0];
            }
            else
            {
                Console.Write("Digite seu usuario de rede: ");
                usuario = Console.ReadLine();
            }
            
            Console.WriteLine("\n=== Configurador de VPN TJRN ===\n");
            
            // Criar configuracao
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string vpnPath = Path.Combine(appData, "FortiClient", "Vpn", "Connections");
            
            if (!Directory.Exists(vpnPath))
            {
                Directory.CreateDirectory(vpnPath);
            }
            
            string configFile = Path.Combine(vpnPath, "TJRN.conn");
            
            // Criar XML
            XmlDocument doc = new XmlDocument();
            XmlElement root = doc.CreateElement("FortiClientVPNProfile");
            
            AddElement(doc, root, "Name", "TJRN");
            AddElement(doc, root, "Type", "ssl");
            AddElement(doc, root, "RemoteGateway", "vpn.tjrn.jus.br");
            AddElement(doc, root, "Port", "10443");
            AddElement(doc, root, "Username", usuario);
            AddElement(doc, root, "AuthMethod", "0");
            AddElement(doc, root, "SavePassword", "true");
            AddElement(doc, root, "DefaultGateway", "true");
            
            doc.AppendChild(root);
            doc.Save(configFile);
            
            Console.WriteLine($"[OK] Configuracao salva em: {configFile}");
            
            // Abrir FortiClient
            string fortiPath = @"C:\Program Files\Fortinet\FortiClient\FortiClient.exe";
            
            if (File.Exists(fortiPath))
            {
                Console.WriteLine("[OK] Abrindo FortiClient...");
                Process.Start(fortiPath);
                
                Thread.Sleep(3000);
                
                Console.WriteLine("\n=== INSTRUCOES ===");
                Console.WriteLine("1. Procure pela conexao 'TJRN' na lista");
                Console.WriteLine("2. Se nao aparecer, clique em '+' para adicionar");
                Console.WriteLine("3. Configure manualmente os dados:");
                Console.WriteLine("   - Nome: TJRN");
                Console.WriteLine("   - Gateway: vpn.tjrn.jus.br");
                Console.WriteLine("   - Porta: 10443");
                Console.WriteLine("   - Usuario: " + usuario);
                Console.WriteLine("4. Clique em Conectar");
                Console.WriteLine("=================\n");
            }
            else
            {
                Console.WriteLine("[ERRO] FortiClient nao encontrado em: " + fortiPath);
            }
            
            Console.WriteLine("Pressione ENTER para sair...");
            Console.ReadLine();
        }
        
        static void AddElement(XmlDocument doc, XmlElement parent, string name, string value)
        {
            XmlElement elem = doc.CreateElement(name);
            elem.InnerText = value;
            parent.AppendChild(elem);
        }
    }
}