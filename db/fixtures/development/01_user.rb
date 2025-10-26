User.seed(:id, [
    { id: 1, username: '田中太郎', email: 'hoge@example.com', password: 'password', admin: false },
    { id: 2, username: '田中二郎', email: 'hoge2@example.com', password: 'password', admin: false },
    { id: 3, username: '管理者', email: 'admin@example.com', password: 'admin123', admin: true },
  ])