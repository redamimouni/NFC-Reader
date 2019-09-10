//
//  NFCTableViewController.swift
//  NfcReader
//
//  Created by Reda Mimouni on 29/08/2017.
//  Copyright © 2017 Reda Mimouni. All rights reserved.
//

import UIKit
import CoreNFC

class NFCTableViewController: UITableViewController {
  
  // Referencie les messages reçus
  private var nfcMessages: [[NFCNDEFMessage]] = []
            
  @IBAction func startNFCSearchButtonTapped(_ sender: Any) {
    var nfcSession: NFCNDEFReaderSession!
    // Créer la session de lecture NFC au moment où l’utilisateur clique sur le bouton
    nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    // Définir le message qui sera afficher sur la dialog
    nfcSession.alertMessage = "You can scan NFC-tags by holding them behind the top of your iPhone."
    // Démarrer la session
    nfcSession.begin()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.register(NFCTableViewCell.self, forCellReuseIdentifier: "NFCTableCell")
  }
  
  class func formattedTypeNameFormat(from typeNameFormat: NFCTypeNameFormat) -> String {
    switch typeNameFormat {
    case .empty:
      return "Empty"
    case .nfcWellKnown:
      return "NFC Well Known"
    case .media:
      return "Media"
    case .absoluteURI:
      return "Absolute URI"
    case .nfcExternal:
      return "NFC External"
    case .unchanged:
      return "Unchanged"
    default:
      return "Unknown"
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return self.nfcMessages.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.nfcMessages[section].count
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let numberOfMessages = self.nfcMessages[section].count
    let headerTitle = numberOfMessages == 1 ? "One Message" : "\(numberOfMessages) Messages"
    
    return headerTitle
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "NFCTableCell", for: indexPath) as! NFCTableViewCell
    let nfcTag = self.nfcMessages[indexPath.section][indexPath.row]
    
    cell.textLabel?.text = "\(nfcTag.records.count) Records"
    cell.accessoryType = .disclosureIndicator
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let nfcTag = self.nfcMessages[indexPath.section][indexPath.row]
    let records = nfcTag.records.map({ String(describing: String(data: $0.payload, encoding: .utf8)!) })
    
    let alertTitle = " \(nfcTag.records.count) Records found in Message"
    let alert = UIAlertController(title: alertTitle, message: records.joined(separator: "\n"), preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    self.present(alert, animated: true, completion: nil)
    self.tableView.deselectRow(at: indexPath, animated: true)
  }
  
}


// MARK: NFCNDEFReaderSessionDelegate

extension NFCTableViewController : NFCNDEFReaderSessionDelegate {
  
  // Appeler quand la session est expiré, invalide ou que l'utilisateur à fermer le dialog
  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    print("NFC-Session invalidated: \(error.localizedDescription)")
  }
  
  // Appler lorcequ'on arrive à scanner des messages NDEF
  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    print("New NFC Message (\(messages.count)) detected:")
    
    for message in messages {
      print(" - \(message.records.count) Records:")
      for record in message.records {
        print("\t- TNF (TypeNameFormat): \(NFCTableViewController.formattedTypeNameFormat(from: record.typeNameFormat))")
        // Le format du record, exemple: media, URI, empty ...
        print("\t- Payload: \(String(data: record.payload, encoding: .utf8)!)")
        // Données du tag, exemple (URL RATP): tag.ratp.fr/?t=1&id=13069
        print("\t- Type: \(record.type)")
        // Type de données en format NDEF
        print("\t- Identifier: \(record.identifier)\n")
        // L’identifiant en format NDEF
      }
    }
    
    // Ajouter le nouveau message à la liste des messages reçus
    self.nfcMessages.append(messages)
    
    // Recharger la table view dans le thread principale
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
}

