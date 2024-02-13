//
//  TaskListViewController.swift
//  ToDoApp
//
//  Created by Serge Bowski on 2/12/24.
//

import UIKit

final class TaskListViewController: UITableViewController {
    private var taskList: [ToDoTask] = []
    private let cellID = "task"
    private let storageManager = StorageManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        fetchData()
    }
    
    @objc private func addNewTask() {
        showAlert(withTitle: "New task", andMessage: "What do you want to do?") {
            [unowned self] taskName in
            save(taskName)
        }
    }
    
    private func showAlert(
        withTitle title: String,
        andMessage message: String,
        completion: ((String) -> Void)? = nil
        
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let saveAction = UIAlertAction(
            title: "Save Task",
            style: .default
        ) { _ in
            guard let taskName = alert.textFields?.first?.text,
                  !taskName.isEmpty else {
                return
            }
            completion?(taskName)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = "New task"
        }
        
        present(alert, animated: true)
    }
    
    private func save(_ taskName: String) {
        let task = ToDoTask(context: storageManager.persistentContainer.viewContext)
        task.title = taskName
        taskList.append(task)
        
        let indexPath = IndexPath(row: taskList.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        
        storageManager.saveContext()
    }
    
    private func update(_ taskName: String, at indexPath: IndexPath) {
        let task = taskList[indexPath.row]
        task.title = taskName
        
        storageManager.saveContext()
    }
    
    private func fetchData() {
        let fetchRequest = ToDoTask.fetchRequest()
        
        do {
           taskList = try storageManager.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print(error)
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        taskList.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let toDoTask = taskList[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = toDoTask.title
        
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - Setup UI
private extension TaskListViewController {
    func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.backgroundColor = .systemBlue
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        // Add button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        navigationController?.navigationBar.tintColor = .white
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController {
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        showAlert(withTitle: "Edit Task", andMessage: "It seems that plans have changed") {
            [unowned self] taskName in
            update(taskName, at: indexPath)

            tableView.reloadData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            storageManager
                .persistentContainer
                .viewContext
                .delete(taskList[indexPath.row])
            
            storageManager.saveContext()
            fetchData()
            
            tableView.reloadData()
        }
    }
}
