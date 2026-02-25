import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';

import CourseListContainer from './course/CourseListContainer';
import AddOrEditCourseContainer from './course/AddOrEditCourseContainer';

const App = () => {
    return (
        <div>
            <Router>
                <Routes>
                    <Route path="/" element={<CourseListContainer />} />
                    <Route path="/course" element={<AddOrEditCourseContainer />} />
                    <Route path="/course/:id" element={<AddOrEditCourseContainer />} />
                </Routes>
            </Router>
        </div>
    );
};

export default App;