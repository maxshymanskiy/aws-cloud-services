import React, { useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import toastr from 'toastr';
import * as courseAction from '../../action/CourseAction';
import * as authorAction from '../../action/AuthorAction';
import CourseForm from './CourseForm';
import { authorsFormattedForDropdown } from '../../selectors/selectors';

const AddOrEditCourseContainer = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const dispatch = useDispatch();

    const initialValues = useSelector(state => {
        if (id && state.selectedCourseReducer.course && id === state.selectedCourseReducer.course.id) {
            return state.selectedCourseReducer.course;
        }
        return undefined;
    });

    const authors = useSelector(state =>
        authorsFormattedForDropdown(state.authorReducer.authors)
    );

    useEffect(() => {
        dispatch(courseAction.getCourseAction(id))
            .catch(error => toastr.error(error));

        dispatch(authorAction.getAuthorsAction())
            .catch(error => toastr.error(error));
    }, [dispatch, id]);

    const handleSave = (values) => {
        const course = {
            id: values.id,
            title: values.title,
            watchHref: values.watchHref,
            authorId: values.authorId,
            length: values.length,
            category: values.category
        };

        dispatch(courseAction.saveCourseAction(course))
            .then(() => {
                toastr.success('Course saved');
                navigate('/');
            }).catch(error => toastr.error(error));
    };

    const handleCancel = (event) => {
        event.preventDefault();
        navigate('/');
    };

    const heading = initialValues && initialValues.id ? 'Edit' : 'Add';

    return (
        <div className="container">
            <CourseForm
                heading={heading}
                authors={authors || []}
                handleSave={handleSave}
                handleCancel={handleCancel}
                initialValues={initialValues}
            />
        </div>
    );
};

export default AddOrEditCourseContainer;
